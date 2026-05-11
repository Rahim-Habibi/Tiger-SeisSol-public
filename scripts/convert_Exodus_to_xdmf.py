import numpy as np
import seissolxdmfwriter as sxw
import os
from numpy.ma import masked
import argparse
import LightExodusReader


parser = argparse.ArgumentParser(
    description="convert Exodus (from Tiger) to SeisSol format"
)
parser.add_argument("input_file", help="Exodus input file")
parser.add_argument(
    "--fault",
    dest="fault",
    action="store_true",
    help="write fault output (but not volume output)",
)
parser.add_argument(
    "--alldt",
    dest="alldt",
    action="store_true",
    help="write all time steps (else writes only last",
)
args = parser.parse_args()

if not os.path.exists("output"):
    os.makedirs("output")

er = LightExodusReader(args.input_file)

xyz = er.readgeom()
lVarNames = er.read_var_names()
lVarNames_selected = [
    "stress_xx",
    "stress_xy",
    "stress_xz",
    "stress_yy",
    "stress_yz",
    "stress_zz",
    "ePressure",
]
lVarNames_selected_seissol_name = ["s_xx", "s_xy", "s_xz", "s_yy", "s_yz", "s_zz"]

connect_all = None
dData_all = None

times = range(0, er.ntime) if args.alldt else [0]

for i in range(1, er.num_el_blk + 1):
    connect = er.readconnect(i)
    if connect.shape[1] == 3 and args.fault:
        name = f"fault{i}"
    elif connect.shape[1] == 4 and not args.fault:
        name = "region"
    else:
        continue
    # merge all blocks together
    dData = er.read_var_data(i, not args.alldt)
    # compute effective stress
    for key in ["stress_xx", "stress_yy", "stress_zz"]:
        dData[key] = dData[key] + dData["ePressure"]

    if args.fault:
        # in this case we do no merge blocks
        sxw.write_seissol_output(
            name,
            xyz,
            connect,
            lVarNames_selected_seissol_name,
            [dData[key] for key in lVarNames_selected[:-1]],
            1.0,
            times,
        )
    else:
        if connect_all is None:
            connect_all = connect.copy()
            dData_all = dData.copy()
        else:
            connect_all = np.vstack((connect_all, connect))
            for k in dData_all:
                dData_all[k] = np.hstack((dData_all[k], dData[k]))


if not args.fault:
    times = range(0, er.ntime) if args.alldt else [0]
    sxw.write_seissol_output(
        name,
        xyz,
        connect_all,
        lVarNames_selected_seissol_name,
        [dData_all[key] for key in lVarNames_selected[:-1]],
        1.0,
        times,
    )
