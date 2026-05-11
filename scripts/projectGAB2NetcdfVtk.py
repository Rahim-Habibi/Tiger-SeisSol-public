from netCDF4 import Dataset
from scipy.interpolate import griddata
import argparse
import numpy as np
from writeNetcdf import writeNetcdf
import vtk
from vtk.util import numpy_support


class AffineMap:
    def __init__(self, ua, ub, ta, tb):
        # matrix arguments
        self.ua = ua
        self.ub = ub
        # translation arguments
        self.ta = ta
        self.tb = tb


class Grid2D:
    def __init__(self, u, v):
        # matrix arguments
        self.u = u
        self.v = v
        # translation arguments
        self.ug, self.vg = np.meshgrid(u, v)


def Gridto2Dlocal(lengths, myAffineMap, fault_fname, ldataName):
    # project fault coordinates to 2D local coordinate system
    xa = np.dot(points, myAffineMap.ua) + myAffineMap.ta
    xb = np.dot(points, myAffineMap.ub) + myAffineMap.tb
    if args.verbose:
        print("xa", np.amin(xa), np.amax(xa))
        print("xb", np.amin(xb), np.amax(xb))
    xab = np.vstack((xa, xb)).T

    u = np.arange(min(0.0, np.amin(xa)), max(lengths[0], np.amax(xa)) + dx, dx)
    v = np.arange(min(0.0, np.amin(xb)), max(lengths[1], np.amax(xb)) + dx, dx)
    mygrid = Grid2D(u, v)

    lgridded_myData = []
    for dataName in ldataName:
        # Read Data
        myData = numpy_support.vtk_to_numpy(outputGrid.GetPointData().GetArray(dataName))
        if args.verbose:
            print(dataName, np.amin(myData), np.amax(myData))
        # grid data and tapper to 30MPa
        gridded_myData = griddata(xab, myData, (mygrid.ug, mygrid.vg), method="nearest")
        gridded_myData_lin = griddata(
            xab, myData, (mygrid.ug, mygrid.vg), method="linear", fill_value=np.nan
        )
        if args.verbose:
            print("using linear interpolation when possible, else nearest neighbor")
        ids_in = ~np.isnan(gridded_myData_lin)
        gridded_myData[ids_in] = gridded_myData_lin[ids_in]

        # gridded_myData[gridded_myData > 20e6] = 20e6
        # gridded_myData[gridded_myData < -20e6] = -20e6

        plot_data = False
        if plot_data and dataName == "Pn0":
            import matplotlib.pyplot as plt

            # plt.plot(xa, xb, 'x')
            plt.pcolormesh(mygrid.ug, mygrid.vg, gridded_myData)
            plt.colorbar()
            plt.axis("equal")
            plt.show()
        lgridded_myData.append(gridded_myData)

    return mygrid, lgridded_myData


def WriteAllNetcdf(mygrid, lgridded_myData, sName, ldataName):
    """
    for i, var in enumerate(ldataName):
        writeNetcdf(
            f"{sName}_{var}",
            [mygrid.u, mygrid.v],
            [var],
            [lgridded_myData[i]],
            paraview_readable=True,
        )
    """
    writeNetcdf(
        f"{sName}_TsTdTn",
        [mygrid.u, mygrid.v],
        ldataName,
        lgridded_myData,
        paraview_readable=False,
    )


# parsing python arguments
parser = argparse.ArgumentParser(
    description="project 3d fault output from Norcia onto 2d grid to be read with Asagi"
)
parser.add_argument("fault", help="fault.xdmf filename")
parser.add_argument(
    "--verbose",
    dest="verbose",
    action="store_true",
    help="write more info",
)
args = parser.parse_args()

reader = vtk.vtkPolyDataReader()
reader.SetFileName(args.fault)
reader.Update()
outputGrid = reader.GetOutput()

if "4.vtk" in args.fault:
    fault4 = True
    print("use parameters for fault 4")
else:
    fault4 = False
    print("use parameters for fault 5")

points = numpy_support.vtk_to_numpy(outputGrid.GetPoints().GetData())
# generate grid
# Fault 4
dx = 25.0

# Fault specific data for projecting to 2D local coordinate system
# Fault
if fault4:
    xu1 = np.array([3351.1, 0, -500.0])
    xu2 = np.array([8014.1, 10e3, -500.0])
    xd1 = np.array([2805.15, 0, -3e3])
    faultnormal = np.array([0.88907914,-0.41445666,-0.1943292])
else:
    xu1 = np.array([4750.0, 3000, -500.0])
    xu2 = np.array([2202.21, 10e3, -500.0])
    xd1 = np.array([4204.05, 3000, -3e3])
    faultnormal = np.array([0.92050929,0.33503803,-0.20102778])

ua = xu2 - xu1
la = np.linalg.norm(ua)
ua = ua / la
ub = np.cross(faultnormal, ua)
lb = np.linalg.norm(ub)
ub = ub / lb


ta = -np.dot(xu1, ua)
tb = -np.dot(xu1, ub)

if args.verbose:
    print(
        f"""components: !AffineMap
      matrix:
        ua: [{ua[0]}, {ua[1]}, {ua[2]}]
        ub: [{ub[0]}, {ub[1]}, {ub[2]}]
      translation:
        ua: {ta}
        ub: {tb}
    """
    )

myAffineMap = AffineMap(ua, ub, ta, tb)
ldataName = ["Ts0", "Td0", "Pn0"]
grid, lgridded_myData = Gridto2Dlocal([la, lb], myAffineMap, args.fault, ldataName)

fn = "fault4_full" if fault4 else "fault5_full"
ldataName = ["T_s", "T_d", "T_n"]
WriteAllNetcdf(grid, lgridded_myData, f"SeisSolSetup/ASAGI_files/{fn}", ldataName)
