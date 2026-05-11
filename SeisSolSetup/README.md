# Tiger to Seissol workflow

```
python ../scripts/convert_Exodus_to_xdmf.py ../tiger_files/THM-criterion-ex-flood_out.e
python ../scripts/interpolate_seissol_data_to_grid.py region.xdmf --Data s_xx s_xy s_xz s_yy s_yz s_zz  --idt 0 --box "50 1600 8100 0 10e3 -3e3 -500" --add "_background"
python ../scripts/interpolate_seissol_data_to_grid.py region.xdmf --Data s_xx s_xy s_xz s_yy s_yz s_zz  --idt 0 --box "20 3300 5600  2800 5800 -2500 -1600" --add "_near_wells"
rm region.h5 region.xdmf
mv gridded_asagi_dx* ASAGI_files/
```
