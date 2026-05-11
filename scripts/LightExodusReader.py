import netCDF4
import numpy as np
from numpy.ma import masked


class LightExodusReader:
    def __init__(self, fname):
        self.nc = netCDF4.Dataset(fname)
        self.nnodes = self.nc.dimensions["num_nodes"].size
        self.num_el_blk = self.nc.dimensions["num_el_blk"].size
        self.num_elem_var = 0
        self.num_nod_var = 0
        if "num_elem_var" in self.nc.dimensions:
            self.num_elem_var = self.nc.dimensions["num_elem_var"].size
        if "num_nod_var" in self.nc.dimensions:
            self.num_nod_var = self.nc.dimensions["num_nod_var"].size
        self.time_whole = self.nc["time_whole"][:]
        self.ntime = self.nc.dimensions["time_step"].size
        self.var_names = self.read_var_names()

    def readgeom(self):
        xyz = np.zeros((self.nnodes, 3))
        for i, var in enumerate(["x", "y", "z"]):
            xyz[:, i] = self.nc[f"coord{var}"][:]
        return xyz

    def readconnect(self, i):
        return self.nc[f"connect{i}"][:] - 1

    def get_blocks_id_by_dim(self, dim=3):
        block_ids = []
        for i in range(1, self.num_el_blk + 1):
            connect = self.readconnect(i)
            if connect.shape[1] == (dim + 1):
                block_ids.append(i)
        return block_ids

    def compute_merged_connect(self, dim=3):
        connect_all = None
        for i in range(1, self.num_el_blk + 1):
            connect = self.readconnect(i)
            if connect.shape[1] == (dim + 1):
                if connect_all is None:
                    connect_all = connect.copy()
                    tags_all = np.zeros(connect.shape[0]) + i
                else:
                    connect_all = np.vstack((connect_all, connect))
                    tags_all = np.hstack((tags_all, np.zeros(connect.shape[0]) + i))
        return connect_all, tags_all

    def read_var_names(self):
        def decode_var(barray):
            for ib, by in enumerate(barray):
                if by is masked:
                    break
            return barray[:ib].tobytes().decode()

        varNames = {"elem": {}, "nod": {}}
        for k in range(self.num_elem_var):
            name = decode_var(self.nc["name_elem_var"][k])
            varNames["elem"][name] = k + 1
        for k in range(self.num_nod_var):
            name = decode_var(self.nc["name_nod_var"][k])
            varNames["nod"][name] = k + 1
        return varNames

    def read_var_data(self, var, idt=slice(None), block="3D"):
        if var in self.var_names["nod"].keys():
            elemental = False
        elif var in self.var_names["elem"].keys():
            elemental = True
        else:
            raise ValueError(
                f"{var} not found in exodus variables", self.read_var_names()
            )
        stype = "elem" if elemental else "nod"
        ivar = self.var_names[stype][var]
        if elemental:
            if block not in ["2D", "3D"]:
                aData = self.nc[f"vals_{stype}_var{ivar}eb{block}"][idt, :]
            else:
                dim = int(block[0])
                aData = None
                for i in range(1, self.num_el_blk + 1):
                    connect = self.readconnect(i)
                    if connect.shape[1] == dim + 1:
                        aDatai = self.nc[f"vals_{stype}_var{ivar}eb{i}"][idt, :]
                        if aData is None:
                            aData = aDatai.copy()
                        else:
                            aData = np.hstack((aData, aDatai))
        else:
            aData = self.nc[f"vals_{stype}_var{ivar}"][idt, :]
        return aData

    def read_stress_components(self, idt, block):
        aData = {}
        for var in [
            "stress_xx",
            "stress_yy",
            "stress_zz",
            "stress_xy",
            "stress_xz",
            "stress_yz",
        ]:
            newvar = "s_" + var[-2:]
            aData[newvar] = self.read_var_data(var, idt, block=block)
        return aData
