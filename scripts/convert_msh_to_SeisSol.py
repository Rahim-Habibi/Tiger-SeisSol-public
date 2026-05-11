import argparse

parser = argparse.ArgumentParser(
    description="convert msh file used by Tiger to msh readable by pumgen(seissol)"
)
parser.add_argument("input_file")
parser.add_argument("output_file")
args = parser.parse_args()


def skip_block(fid, to_write):
    for line in fid:
        if line.startswith("$"):
            if not (
                line.startswith("$PhysicalNames")
                or line.startswith("$EndPhysicalNames")
            ):
                to_write.append(line)
            else:
                print("skipped:", line)
            line = fid.readline()
            print(line, end="")
            return line, to_write
        else:
            to_write.append(line)


skipped = ["inj", "Well1", "Well2", "Well3"]
new_boundaries = {}
new_boundaries["Right"] = 105
new_boundaries["Left"] = 105
new_boundaries["Top"] = 105
new_boundaries["Bottom"] = 105
new_boundaries["Front"] = 105
new_boundaries["Back"] = 105
new_boundaries["Fault1"] = 103
new_boundaries["Fault2"] = 167

to_write = []
with open(args.input_file) as fid:
    line = fid.readline()
    to_write.append(line)
    assert line.startswith("$MeshFormat")
    line, to_write = skip_block(fid, to_write)

    assert line.startswith("$PhysicalNames")
    nboundaries = int(fid.readline())
    boundaries = {}
    for i in range(1, nboundaries + 1):
        line = fid.readline()
        _, ib, name = line.split()
        boundaries[int(ib)] = eval(name)
    boundaries[134] = "134"
    boundaries[135] = "135"
    print(boundaries)
    # skip the $EndPhysicalNames
    line = fid.readline()
    line = fid.readline()
    to_write.append(line)
    assert line.startswith("$Nodes")
    line, to_write = skip_block(fid, to_write)
    to_write.append(line)

    assert line.startswith("$Elements")
    line = fid.readline()
    elements_lines = []
    for line in fid:
        if line.startswith("$"):
            break
        # print(line, end="")
        items = line.split()
        bc = boundaries[int(items[3])]
        if bc in new_boundaries:
            items[3] = str(new_boundaries[bc])
            new_line = " ".join(items) + "\n"
            elements_lines.append(new_line)
        elif bc in skipped:
            pass
        else:
            elements_lines.append(line)
    elements_lines.insert(0, f"{len(elements_lines)}\n")
    to_write = to_write + elements_lines
    to_write.append(line)
fn = args.output_file

with open(fn, "w") as f:
    for line in to_write:
        f.write(f"{line}")
print(f"done writing {fn}")
