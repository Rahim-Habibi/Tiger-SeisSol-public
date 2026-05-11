#!/usr/bin/env python3
from sklearn.decomposition import PCA
from netCDF4 import Dataset
from scipy.interpolate import griddata
import seissolxdmf
import numpy as np
from asagiwriter import writeNetcdf
from scipy.ndimage import gaussian_filter
import os
from typing import List, Tuple, Optional
import argparse
from LightExodusReader import LightExodusReader


def compute_unit_vectors(xyz, connect):
    nElements = np.shape(connect)[0]

    # compute triangle normals
    un = np.cross(
        xyz[connect[:, 1], :] - xyz[connect[:, 0], :],
        xyz[connect[:, 2], :] - xyz[connect[:, 0], :],
    )
    norm = np.apply_along_axis(np.linalg.norm, 1, un)
    un = un / norm.reshape((nElements, 1))

    # normal orientation
    vref = np.zeros(3)
    vref[0] = 0.1
    vref[1] = 0.0
    vref[2] = -1.0
    print(f"using reference vector {vref}")
    mysign = np.sign(np.dot(un, vref))
    un = un * mysign[:, np.newaxis]

    un = un.T
    # compute Strike and dip direction
    us = np.zeros(un.shape)
    us[0, :] = un[1, :]
    us[1, :] = -un[0, :]
    norm = np.apply_along_axis(np.linalg.norm, 0, us)
    us = us / norm
    ud = np.cross(un.T, us.T).T
    return (us, ud, un)


def compute_stress_tensor(stress_components):
    """
    Constructs the stress tensor from stress components.

    Parameters:
    - stress_components (dict): Dictionary containing stress components.

    Returns:
    - np.ndarray: A (n_data, 3, 3) array representing the stress tensor for each data point.
    """
    n_data = stress_components["s_xx"].shape[0]
    stress = np.zeros((n_data, 3, 3))
    stress[:, 0, 0] = stress_components["s_xx"]
    stress[:, 1, 1] = stress_components["s_yy"]
    stress[:, 2, 2] = stress_components["s_zz"]
    stress[:, 0, 1] = stress_components["s_xy"]
    stress[:, 0, 2] = stress_components["s_xz"]
    stress[:, 1, 2] = stress_components["s_yz"]
    # Ensure the tensor is symmetric
    stress[:, 1, 0] = stress[:, 0, 1]
    stress[:, 2, 0] = stress[:, 0, 2]
    stress[:, 2, 1] = stress[:, 1, 2]

    return stress


def compute_tractions(stress, unit_normals):
    """
    Computes the traction vectors using NumPy operations for efficiency.

    Parameters:
    - stress (np.ndarray): A (n_data, 3, 3) array representing the stress tensor for each data point.
    - unit_normals (np.ndarray): A (3, n_data) array of unit normal vectors.

    Returns:
    - np.ndarray: Traction vectors for each data point.
    """
    # Reshape unit_normals to enable broadcasting
    normals_reshaped = unit_normals.T[..., np.newaxis]
    # Compute tractions using matrix multiplication
    tractions = np.sum(stress * normals_reshaped, axis=1)
    return tractions.squeeze()


def compute_traction_components_nodal(
    node2elements, selected_vertex, us, ud, un, stress
):
    n_vertex = len(selected_vertex)
    T_n = np.zeros(n_vertex)
    T_s = np.zeros(n_vertex)
    T_d = np.zeros(n_vertex)

    mapping = {}
    for k, node in enumerate(selected_vertex):
        mapping[node] = k
        elems = node2elements[node]
        una = np.average(un[:, elems[:]], axis=1)
        usa = np.average(us[:, elems[:]], axis=1)
        uda = np.average(ud[:, elems[:]], axis=1)
        tractions = stress[node, :, :].dot(una)
        T_n[k] = np.sum(tractions.T * una, axis=0)
        T_s[k] = np.sum(tractions.T * usa, axis=0)
        T_d[k] = np.sum(tractions.T * uda, axis=0)
    out = {}
    out["T_n"] = T_n
    out["T_s"] = T_s
    out["T_d"] = T_d
    return out


def compute_traction_components(tractions, u_s, u_d, u_n):
    """
    Computes the traction components in different directions.

    Parameters:
    - tractions (np.ndarray): Traction vectors for each data point.
    - u_s (np.ndarray): Unit vectors in the s-direction.
    - u_d (np.ndarray): Unit vectors in the d-direction.
    - u_n (np.ndarray): Unit vectors in the n-direction.

    Returns:
    - dictionnary: Components of traction in n, s, and d directions.
    """
    out = {}
    out["T_n"] = np.sum(tractions * u_n.T, axis=1)
    out["T_s"] = np.sum(tractions * u_s.T, axis=1)
    out["T_d"] = np.sum(tractions * u_d.T, axis=1)

    return out


class AffineMap:
    def __init__(self, ua: np.ndarray, ub: np.ndarray, ta: np.ndarray, tb: np.ndarray):
        """
        Initialize AffineMap with matrix and translation arguments.

        Parameters:
        ua (np.ndarray): Matrix argument for first axis.
        ub (np.ndarray): Matrix argument for second axis.
        ta (np.ndarray): Translation argument for first axis.
        tb (np.ndarray): Translation argument for second axis.
        """
        self.ua = ua
        self.ub = ub
        self.ta = ta
        self.tb = tb


class Grid2D:
    def __init__(self, u: np.ndarray, v: np.ndarray):
        """
        Initialize Grid2D with u and v matrices.

        Parameters:
        u (np.ndarray): U-axis values.
        v (np.ndarray): V-axis values.
        """
        self.u = u
        self.v = v
        self.ug, self.vg = np.meshgrid(u, v)


def gridto2Dlocal(
    coords: np.ndarray,
    lengths: List[float],
    dx: float,
    myAffineMap: AffineMap,
    traction_components,
    gaussian_kernel: Optional[List[float]],
    taper: Optional[List[float]],
) -> Tuple[Grid2D, dict]:
    """
    Project fault coordinates to 2D local coordinate system and grid data.

    Parameters:
    sx: seissolxdmf reader,
    coords (np.ndarray): Fault coordinates.
    lengths (List[float]): Lengths for grid calculation.
    dx (float): Grid spacing.
    myAffineMap (AffineMap): AffineMap object containing matrix and translation data.
    ldataName (List[str]): List of data names to be processed.
    gaussian_kernel (Optional[List[float]]): Gaussian kernel for smoothing.
    taper (Optional[List[float]]): Taper values for clipping data.

    Returns:
    Tuple[Grid2D, dict]: Gridded 2D local coordinate system and corresponding data.
    """
    xa = np.dot(coords, myAffineMap.ua) + myAffineMap.ta
    xb = np.dot(coords, myAffineMap.ub) + myAffineMap.tb
    xab = np.vstack((xa, xb)).T

    u = np.arange(min(0.0, np.amin(xa)), max(lengths[0], np.amax(xa)) + dx, dx)
    v = np.arange(min(0.0, np.amin(xb)), max(lengths[1], np.amax(xb)) + dx, dx)
    mygrid = Grid2D(u, v)

    traction_components_gridded = {}
    for dataName, myData in traction_components.items():
        # grid data and tapper to 30MPa
        gridded_myData = griddata(xab, myData, (mygrid.ug, mygrid.vg), method="nearest")
        gridded_myData_lin = griddata(
            xab, myData, (mygrid.ug, mygrid.vg), method="linear", fill_value=np.nan
        )
        # using linear interpolation when possible, else nearest neighbor
        ids_in = ~np.isnan(gridded_myData_lin)
        gridded_myData[ids_in] = gridded_myData_lin[ids_in]
        if gaussian_kernel:
            gridded_myData = gaussian_filter(gridded_myData, sigma=gaussian_kernel / dx)

        if taper:
            taper_value = taper * 1e6
            gridded_myData[gridded_myData > taper_value] = taper_value
            gridded_myData[gridded_myData < -taper_value] = -taper_value

        plot_data = False
        if plot_data and dataName == ldataName[0]:
            import matplotlib.pyplot as plt

            plt.pcolormesh(mygrid.ug, mygrid.vg, gridded_myData)
            plt.colorbar()
            plt.axis("equal")
            plt.show()
        traction_components_gridded[dataName] = gridded_myData

    return mygrid, traction_components_gridded


def writeAllNetcdf(
    mygrid: Grid2D,
    keys: List[str],
    traction_components_gridded: dict,
    sName: str,
    paraview_readable: bool = False,
) -> None:
    """
    Write gridded data to NetCDF files.

    Parameters:
    mygrid (Grid2D): Gridded 2D local coordinate system.
    keys: list of keys to write.
    traction_components_gridded (dict): Dictionary of gridded data arrays.
    sName (str): prefix for the output files.
    paraview_readable (bool): Whether to make the NetCDF files ParaView readable.
    """
    if paraview_readable:
        for key, value in traction_components_gridded.items():
            writeNetcdf(
                f"{sName}_{key}",
                [mygrid.u, mygrid.v],
                [key],
                [value],
                paraview_readable=True,
            )
    for key in keys:
        assert key in traction_components_gridded.keys()
    writeNetcdf(
        f"{sName}_TsTdTn",
        [mygrid.u, mygrid.v],
        keys,
        [traction_components_gridded[k] for k in keys],
        paraview_readable=False,
    )


def generate_input_files(
    fault_filename: str,
    dx: float,
    gaussian_kernel: Optional[float] = None,
    taper: Optional[float] = None,
    paraview_readable: bool = False,
) -> None:
    """
    Generate input files for the given fault data.

    Parameters:
    fault_filename (str): Filename of the fault data.
    dx (float): Grid spacing.
    gaussian_kernel (Optional[float]): Gaussian kernel for smoothing.
    taper (Optional[float]): Taper values for clipping data.
    paraview_readable (bool): Whether to make the NetCDF files ParaView readable.
    """
    if not os.path.exists("ASAGI_files"):
        os.makedirs("ASAGI_files")

    # Compute fault centroids
    er = LightExodusReader(fault_filename)
    elemental = "stress_xx" in er.var_names["elem"].keys()
    idt = er.ntime - 1
    connect, tags = er.compute_merged_connect(2)
    block = "2D"
    tags = tags.astype(int)

    if not elemental:

        def generate_node_lookup(connect):
            nodes_per_element = connect.shape[1]
            flat_connect = connect.flatten()
            nodes = set(flat_connect)
            elements = {}
            for i in nodes:
                elements[i] = []
            for k, node in enumerate(flat_connect):
                elements[node].append(k // nodes_per_element)
            return elements

        node2elements = generate_node_lookup(connect)

    xyz = er.readgeom()
    us, ud, un = compute_unit_vectors(xyz, connect)

    if elemental:
        faultCentroids = (1.0 / 3.0) * (
            xyz[connect[:, 0]] + xyz[connect[:, 1]] + xyz[connect[:, 2]]
        )

    # unique_tags = np.unique(tags)
    # print(unique_tags)
    template_yaml = f"""!Any
 components:\n"""

    itag = 0
    tag = "2D"
    # for itag, tag in enumerate(unique_tags):
    # ids = np.where(tags == tag)[0]
    # connect_selected = connect[ids, :]
    selected_vertex = list(set(connect.flatten()))
    stress_components = er.read_stress_components(idt, tag)
    stress = compute_stress_tensor(stress_components)
    if elemental:
        tractions = compute_tractions(stress, un)
        traction_components = compute_traction_components(tractions, us, ud, un)
    else:
        traction_components = compute_traction_components_nodal(
            node2elements, selected_vertex, us, ud, un, stress
        )

    xyz_selected = xyz[selected_vertex, :]
    vertex_selected = faultCentroids if elemental else xyz_selected
    # Perform PCA to get principal axes
    pca = PCA(n_components=2)
    points = pca.fit_transform(xyz_selected)
    la, lb = np.amax(points, axis=0) - np.amin(points, axis=0)
    ua, ub = pca.components_
    lower_left = np.argmin(np.sum(points, axis=1))
    xu1 = xyz_selected[lower_left]

    ta = -np.dot(xu1, ua)
    tb = -np.dot(xu1, ub)
    fault_tag = 3 if itag == 0 else 66 + itag

    template_yaml += f"""  - !GroupFilter
    groups: {fault_tag}
    components: !AffineMap
      matrix:
        ua: [{ua[0]}, {ua[1]}, {ua[2]}]
        ub: [{ub[0]}, {ub[1]}, {ub[2]}]
      translation:
        ua: {ta}
        ub: {tb}
      components: !Any
        - !ASAGI
            file: ASAGI_files/fault{tag}_TsTdTn.nc
            parameters: [T_s, T_d, T_n]
            var: data
            interpolation: linear
        - !ConstantMap
          map:
            T_s: 0.0
            T_d: 0.0
            T_n: -1e7\n"""
    myAffineMap = AffineMap(ua, ub, ta, tb)
    grid, traction_components_gridded = gridto2Dlocal(
        vertex_selected,
        [la, lb],
        dx,
        myAffineMap,
        traction_components,
        gaussian_kernel,
        taper,
    )

    fn = f"fault{tag}"
    keys = ["T_s", "T_d", "T_n"]
    writeAllNetcdf(
        grid,
        keys,
        traction_components_gridded,
        f"SeisSolSetup/ASAGI_files/{fn}",
        paraview_readable,
    )

    fname = "SeisSolSetup/TsTdTn.yaml"
    with open(fname, "w") as fid:
        fid.write(template_yaml)
    print(f"done writing {fname}")


def main() -> None:
    """
    Main function to parse arguments and generate input files
    by projecting 3D fault output onto 2D grids for ASAGI.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Project 3D fault output onto 2D grids to be read with ASAGI. "
            "One grid per fault tag."
        )
    )
    parser.add_argument("fault_filename", help="Fault.xdmf filename")
    parser.add_argument(
        "--dx",
        nargs=1,
        help="Grid sampling",
        type=float,
        default=[100.0],
    )
    parser.add_argument(
        "--gaussian_kernel",
        metavar="sigma_m",
        nargs=1,
        help="Apply a Gaussian kernel to smooth out input stresses",
        type=float,
    )
    parser.add_argument(
        "--taper",
        nargs=1,
        help="Taper stress value (MPa)",
        type=float,
    )
    parser.add_argument(
        "--paraview_readable",
        dest="paraview_readable",
        action="store_true",
        help="Write NetCDF files readable by ParaView",
        default=False,
    )

    args = parser.parse_args()
    generate_input_files(
        args.fault_filename,
        args.dx[0],
        args.gaussian_kernel[0] if args.gaussian_kernel else None,
        args.taper[0] if args.taper else None,
        args.paraview_readable,
    )


if __name__ == "__main__":
    main()
