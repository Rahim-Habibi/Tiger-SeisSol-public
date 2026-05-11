from paraview import simple
import argparse

parser = argparse.ArgumentParser(description="convert vtk output to exodus")
parser.add_argument("input_file", help="SeisSol input file in vtk format")
parser.add_argument("output_file", help="exodus file")
args = parser.parse_args()

reader = simple.XDMFReader(FileNames=[args.input_file])

# reader = simple.OpenDataFile(args.input_file)
reader.CellArrayStatus = [
    "sigma_xx",
    "sigma_xy",
    "sigma_xz",
    "sigma_yy",
    "sigma_yz",
    "sigma_zz",
]
reader = simple.ExtractTimeSteps(Input=reader, TimeStepIndices=[1])
writer = simple.CreateWriter(args.output_file, reader)
writer.WriteAllTimeSteps = 1
writer.UpdatePipeline()
