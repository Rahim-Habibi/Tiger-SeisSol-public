import argparse
import numpy as np
import seissolxdmfwriter as sxw
import os
from LightExodusReader import LightExodusReader
import vtk
from vtk.util import numpy_support


def ComputeUsUdUn(xyz, connect):
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
    vref[0] = 0.0
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

def diff_stress_components(aData1, aData2):
    for var in [
        "s_xx",
        "s_yy",
        "s_zz",
        "s_xy",
        "s_xz",
        "s_yz",
    ]:
        aData1[var] -= aData2[var]
    return aData1


def gen_stress_tensor(stress_components):
    Stress = np.zeros((nData, 3, 3))
    Stress[:, 0, 0] = stress_components["s_xx"]
    Stress[:, 1, 1] = stress_components["s_yy"]
    Stress[:, 2, 2] = stress_components["s_zz"]
    Stress[:, 0, 1] = stress_components["s_xy"]
    Stress[:, 0, 2] = stress_components["s_xz"]
    Stress[:, 1, 2] = stress_components["s_yz"]
    Stress[:, 1, 0] = Stress[:, 0, 1]
    Stress[:, 2, 0] = Stress[:, 0, 2]
    Stress[:, 2, 1] = Stress[:, 1, 2]
    return Stress


def write_vtk(filename, xyz, connect, aData):
    """Filling in vtk arrays with data from hdf5 file."""
    points = vtk.vtkPoints()
    points.SetData(numpy_support.numpy_to_vtk(xyz))

    vtkCells = vtk.vtkCellArray()
    nElements, ndim2 = connect.shape
    connect2 = np.zeros((nElements, ndim2 + 1), dtype=np.int64)
    # number of points in the cell
    connect2[:, 0] = ndim2
    connect2[:, 1:] = connect
    vtkCells.SetCells(nElements, numpy_support.numpy_to_vtkIdTypeArray(connect2))

    if ndim2 == 4:
        unstrGrid = vtk.vtkUnstructuredGrid()
        unstrGrid.SetPoints(points)
        unstrGrid.SetCells(vtk.VTK_TETRA, vtkCells)
    elif ndim2 == 3:
        unstrGrid = vtk.vtkPolyData()
        unstrGrid.SetPoints(points)
        unstrGrid.SetPolys(vtkCells)

    for var in aData.keys():
        # Use numpy_support.numpy_to_vtk to create vtkFloatArrays for your point data
        node_data_array = numpy_support.numpy_to_vtk(
            aData[var], deep=True, array_type=vtk.VTK_FLOAT
        )
        node_data_array.SetName(var)
        node_data_array.SetNumberOfComponents(1)
        unstrGrid.GetPointData().AddArray(node_data_array)

    if ndim2 == 4:
        writer = vtk.vtkXMLUnstructuredGridWriter()
        fn = filename + ".vtu"
    else:
        writer = vtk.vtkPolyDataWriter()
        fn = filename + ".vtk"
    writer.SetFileName(fn)
    writer.SetInputData(unstrGrid)
    writer.Write()
    print(f"done writing {fn}")


parser = argparse.ArgumentParser(description="compute shear and normal stress")
parser.add_argument("input_file", help="Exodus input file")
parser.add_argument(
    "--block",
    dest="block",
    help="possibe values are 3D or a block number",
)
parser.add_argument(
    "--alldt",
    dest="alldt",
    action="store_true",
    help="write all time steps (else writes only last)",
)
parser.add_argument(
    "--transient",
    dest="transient",
    action="store_true",
    help="compute transient tractions x[n]-x[1] for n>=1",
)

args = parser.parse_args()

block = args.block
onlylast = not args.alldt


er = LightExodusReader(args.input_file)
xyz = er.readgeom()
lVarNames = er.read_var_names()
elemental = "stress_xx" in er.var_names["elem"].keys()

times = range(0, er.ntime) if args.alldt else [er.ntime - 1]
ndt = len(times)

aData = er.read_var_data("stress_xx", 0, block=block)
nData = aData.shape[0]

if block in ["2D", "3D"]:
    dim = int(block[0])
    connect, tags = er.compute_merged_connect(dim)
else:
    connect = er.readconnect(block)
isSurface = connect.shape[1] == 3

if isSurface:
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
        nDataT = len(node2elements.keys())
    else:
        nDataT = nData
        Tractions = np.zeros((nDataT, 3))
    us, ud, un = ComputeUsUdUn(xyz, connect)
    Pn0 = np.zeros((ndt, nDataT))
    Ts0 = np.zeros((ndt, nDataT))
    Td0 = np.zeros((ndt, nDataT))

if args.transient:
    stress_comp_1 = er.read_stress_components(0, block)

prefix = os.path.basename(os.path.splitext(args.input_file)[0])
stransient = "_transient" if args.transient else ""

for i, idt in enumerate(times):
    stress_comp = er.read_stress_components(idt, block)
    if args.transient and idt > 0:
        print("computing transient stress")
        stress_comp = diff_stress_components(stress_comp, stress_comp_1)
    if isSurface:
        stransient = f"_transient{i}" if args.transient else ""
        fn = f"{prefix}_tractions_{block}{stransient}"
        Stress = gen_stress_tensor(stress_comp)
        if elemental:
            for j in range(nData):
                Tractions[j] = Stress[j, :, :].dot(un[:, j])
            # compute Traction
            # compute Traction components
            Pn0[i, :] = np.sum(Tractions.T * un, axis=0)
            Ts0[i, :] = np.sum(Tractions.T * us, axis=0)
            Td0[i, :] = np.sum(Tractions.T * ud, axis=0)
            lVarNames = ["Ts0", "Td0", "Pn0"]
            lData = [Ts0, Td0, Pn0]
            sxw.write_seissol_output(
                fn, xyz, connect, lVarNames, lData, 1.0, range(ndt)
            )
        else:
            polynodes = list(node2elements.keys())
            mapping = {}
            for k, node in enumerate(polynodes):
                mapping[node] = k
                elems = node2elements[node]
                una = np.average(un[:, elems[:]], axis=1)
                usa = np.average(us[:, elems[:]], axis=1)
                uda = np.average(ud[:, elems[:]], axis=1)
                Tractions = Stress[node, :, :].dot(una)
                Pn0[i, k] = np.sum(Tractions.T * una, axis=0)
                Ts0[i, k] = np.sum(Tractions.T * usa, axis=0)
                Td0[i, k] = np.sum(Tractions.T * uda, axis=0)
            xyz0 = xyz[polynodes, :]
            connect0 = np.vectorize(mapping.get)(connect)
            print(Pn0.shape, connect0.shape)
            write_vtk(
                fn,
                xyz0,
                connect0,
                {"Pn0": Pn0[i, :], "Ts0": Ts0[i, :], "Td0": Td0[i, :]},
            )
    else:
        fn = f"{prefix}_stress{stransient}_{block}"
        if elemental:
            lVarNames = stress_comp.keys()
            lData = [stress_comp[k] for k in lVarNames]
            sxw.write_seissol_output(
                fn, xyz, connect, lVarNames, lData, 1.0, range(ndt)
            )
        else:
            write_vtk(fn, xyz, connect, stress_comp)
