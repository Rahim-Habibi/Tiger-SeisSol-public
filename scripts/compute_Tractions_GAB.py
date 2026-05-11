import argparse
import seissolxdmf
import numpy as np
import seissolxdmfwriter as sxw
import os


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


parser = argparse.ArgumentParser(description="compute shear and normal stress")
parser.add_argument("xdmf_filename", help="seissol xdmf file")
parser.add_argument(
    "--transient",
    dest="transient",
    action="store_true",
    help="compute transient tractions x[n]-x[1] for n>=1",
)

args = parser.parse_args()


sx = seissolxdmf.seissolxdmf(args.xdmf_filename)
xyz = sx.ReadGeometry()
connect = sx.ReadConnect()

us, ud, un = ComputeUsUdUn(xyz, connect)

Stress = np.zeros((sx.nElements, 3, 3))
Stress0 = np.zeros((sx.nElements, 3, 3))
Tractions = np.zeros((sx.nElements, 3))
Pn0 = np.zeros((sx.ndt, sx.nElements))
Ts0 = np.zeros((sx.ndt, sx.nElements))
Td0 = np.zeros((sx.ndt, sx.nElements))

if args.transient:
    idt=1
    Stress0[:, 0, 0] = sx.ReadData("s_xx", idt)
    Stress0[:, 1, 1] = sx.ReadData("s_yy", idt)
    Stress0[:, 2, 2] = sx.ReadData("s_zz", idt)
    Stress0[:, 0, 1] = sx.ReadData("s_xy", idt)
    Stress0[:, 0, 2] = sx.ReadData("s_xz", idt)
    Stress0[:, 1, 2] = sx.ReadData("s_yz", idt)
    Stress0[:, 1, 0] = Stress0[:, 0, 1]
    Stress0[:, 2, 0] = Stress0[:, 0, 2]
    Stress0[:, 2, 1] = Stress0[:, 1, 2]

for idt in range(sx.ndt):
    Stress[:, 0, 0] = sx.ReadData("s_xx", idt)
    Stress[:, 1, 1] = sx.ReadData("s_yy", idt)
    Stress[:, 2, 2] = sx.ReadData("s_zz", idt)
    Stress[:, 0, 1] = sx.ReadData("s_xy", idt)
    Stress[:, 0, 2] = sx.ReadData("s_xz", idt)
    Stress[:, 1, 2] = sx.ReadData("s_yz", idt)
    Stress[:, 1, 0] = Stress[:, 0, 1]
    Stress[:, 2, 0] = Stress[:, 0, 2]
    Stress[:, 2, 1] = Stress[:, 1, 2]

    if args.transient and idt>0:
        for i in range(3):
            for j in range(3):
                Stress[:, i, j] -= Stress0[:, i, j]

    for i in range(sx.nElements):
        Tractions[i] = Stress[i, :, :].dot(un[:, i])
    # compute Traction
    # compute Traction components
    Pn0[idt,:] = np.sum(Tractions.T * un, axis=0)
    Ts0[idt,:] = np.sum(Tractions.T * us, axis=0)
    Td0[idt,:] = np.sum(Tractions.T * ud, axis=0)

prefix = os.path.basename(os.path.splitext(args.xdmf_filename)[0])
lVarNames = ["Ts0", "Td0", "Pn0"]
lData = [Ts0, Td0, Pn0]
fn  = f"{prefix}_tractions_transient" if args.transient else f"{prefix}_tractions"

sxw.write_seissol_output(
    fn, xyz, connect, lVarNames, lData, 1.0, range(sx.ndt)
)
