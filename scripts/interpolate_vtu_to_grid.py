import vtk
from vtk.util import numpy_support
import numpy as np
import time
import argparse
from writeNetcdf import writeNetcdf

parser = argparse.ArgumentParser(
    description="Read vtu file and project on structured grid, generating a netcdf file"
)
parser.add_argument("filename", help="vtu file")
parser.add_argument(
    "--add2filename",
    help="string to append to filename of the new file",
    type=str,
    default="",
)
parser.add_argument(
    "--box",
    nargs=1,
    metavar=("dx x0 x1 y0 y1 z0 z1"),
    help="structured grid",
    required=True,
)

parser.add_argument(
    "--Data",
    nargs="+",
    required=True,
    metavar=("variable"),
    help="name of variable; all for all stored quantities",
)
parser.add_argument(
    "--paraview_readable",
    dest="paraview_readable",
    action="store_true",
    help="generate paraview readable netcdf file",
)

args = parser.parse_args()
reader = vtk.vtkXMLUnstructuredGridReader()
reader.SetFileName(args.filename)
reader.Update()
outputGrid = reader.GetOutput()

if len(args.box[0].split()) == 7:
    dx, x0, x1, y0, y1, z0, z1 = [float(v) for v in args.box[0].split()]
    z = np.arange(z0, z1 + dx, dx)
    assert isinstance(outputGrid, vtk.vtkUnstructuredGrid)
    is2DGrid = False
elif len(args.box[0].split()) == 5:
    dx, x0, x1, y0, y1 = [float(v) for v in args.box[0].split()]
    z = np.array([0])
    z0 = 0.0
    # assert(isinstance(unstrGrid3d, vtk.vtkPolyData))
    is2DGrid = True
else:
    raise f"wrong number of arguments in args.box {args.box}"

x = np.arange(x0, x1 + dx, dx)
y = np.arange(y0, y1 + dx, dx)

if is2DGrid:
    xx, yy = np.meshgrid(x, y)
else:
    yy, zz, xx = np.meshgrid(y, z, x)

# Create grid image volume
image1Size = [x.shape[0], y.shape[0], z.shape[0]]
image1Origin = [x0, y0, z0]
image1Spacing = [dx, dx, dx]

imageData1 = vtk.vtkImageData()
imageData1.SetDimensions(image1Size)
imageData1.SetOrigin(image1Origin)
imageData1.SetSpacing(image1Spacing)

# Perform the interpolation
probeFilter = vtk.vtkProbeFilter()
probeFilter.SetInputData(imageData1)
probeFilter.SpatialMatchOn()

# Perform the interpolation
probeFilter.SetSourceData(outputGrid)
start = time.time()
print("start prob filter")
probeFilter.Update()
stop = time.time()
print(f"done prob filter in {stop - start} s")

polyout = probeFilter.GetOutput()
probedData = []
for var in args.Data:
    projData = polyout.GetPointData().GetArray(var)
    projDataNp = numpy_support.vtk_to_numpy(projData).reshape(xx.shape)
    probedData.append(projDataNp)
xyz = [x, y] if is2DGrid else [x, y, z]
if args.paraview_readable:
    for i, sdata in enumerate(args.Data):
        writeNetcdf(
            f"gridded_{sdata}_{dx:.0f}{args.add2filename}",
            xyz,
            [sdata],
            [probedData[i]],
            paraview_readable=True,
        )
else:
    writeNetcdf(
        f"gridded_asagi_dx{dx:.0f}{args.add2filename}",
        xyz,
        args.Data,
        probedData,
        False,
    )
