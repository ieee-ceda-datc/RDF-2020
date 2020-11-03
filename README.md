DATC Robust Design Flow
===

IEEE DATC Robust Design Flow (DATC RDF) is intended (i) to preserve and integrate leading research codes, including from past academic contests, and (ii) to  provide a foundation and backplane for academic research in the RTL-to-GDS IC implementation arena.
Implementation and analysis flows have been enhanced by the addition of steps including multi-bit flip-flop clustering, parasitic extraction and antenna checking, as well as a recent contest-winning global router. 
RDF-2020 also opens [a new "Calibrations" direction](https://github.com/ieee-ceda-datc/datc-rdf-timer-calibration) to support academic research on key analyses such as extraction and timing.


DATC RDF: Getting Started
---

### Configuring the Flow

#### Design Configuration

A design consists of Verilog source codes and a configuration file (YAML format).
Refer to an example design benchmark: [Link](benchmarks/test/tv80)

```yaml
name:        tv80s
clock_port:  clk

verilog:     
    - tv80_alu.v
    - tv80_core.v
    - tv80_mcode.v
    - tv80_reg.v
    - tv80s.v
```

Currently, the [IWLS'05 OpenCores benchmark circuits](https://iwls.org/iwls2005/benchmarks.html) are included in the DATC RDF repository for convenience. 


### Library Preparation

We currently support [NanGate45](https://si2.org/open-cell-library/) and [SKYWATER 130](https://github.com/google/skywater-pdk) standard cell libraries.
The NanGate45 cell librariy is fully supported by both the configurable RDF flow and the OpenROAD single-app flow.
The SKYWATER 130 cell library is fully supported by the OpenRAO single-app flow. The configurable RDF flow currently supports the SKYWATER 130 library in a limited way.

To configure the desired library, you need to populate a library configuration file ([Example](techlibs/nangate45/rdf_techlib.yml)).
It specifies necessary technology information, such as the techlef and celllef file names, placement site name, placement finishing cell names, etc.


### Flow Configuration

We currently support two flows:

1. Academic point tool-based configurable flow.
2. [Single-app integrated OpenROAD flow.](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts).


#### Academic Point Tool-Based Configurable Flow

The academic point-tool based flow is a conventional RDF flow, which uses a flow configuration file in YAML format.
An example RDF flow configuration file is shown below ([Example](./run/example_flow.yml)).

```yaml
---

rdf_path: /path/to/rdf/installation/directory
job_dir:  /path/to/rundir

design:  benchmarks/test/i2c/rdf_design.yml
library: techlibs/nangate45/rdf_techlib.yml

flow:
    - stage: synth
      tool: yosys-abc # ABC or Yosys
      user_parms: 
          max_fanout: 16
          script: resyn2
          map:    map
          
    - stage: floorplan
      tool: TritonFP 
      user_parms:
          target_utilization: 20
          aspect_ratio: 1

    - stage: global_place
      tool: FZUplace # RePlAce, EhPlacer, ComPLx, NTUPlace, FZUplace
      user_parms: 
          target_density: 0.4

    - stage: detail_place
      tool: opendp
      user_parms: []

    - stage: cts
      tool: TritonCTS
      user_parms: []

    - stage: global_route
      tool: FastRoute4-lefdef
      user_parms: []

    - stage: detail_route
      tool: TritonRoute
      user_parms: []
```

In the flow configuration, the `design` attribute specifies the design configuration file path; the `library` attribute specifies the path to the library configuration file.


#### Integrated OpenROAD Tool Flow

In the RDF-2020 release, the single-app OpenROAD tool is now part of the DATC RDF. The noteworthy aspects of the single-app OpenROAD tool is that:

* It is implemented using an [open-source physical design database](https://github.com/The-OpenROAD-Project/OpenDB) with Tcl/Python/C++ APIs.
* It supports a flow integration into a single scriptable application.

To try out the integrated OpenROAD tool, we recommend you to refer to the latest OpenROAD flow script in the following repository:

* **OpenROAD Flow**:  https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts


#### Multi-Bit Flip Flop (MBFF) Flow

DATC RDF flow can be configured to perform a MBFF clustering stage after placement. It clusters flip-flops in the given placement and generates MBFF- mapped netlist and DEF. The goal is to minimize clock power by reducing the number of clock sinks and thereby the total sink pin capacitance. The following two flip-flop clustering algorithms have been added into the RDF-2020 flow.

* **FlopTray**: A. B. Kahng, J. Li, and L. Wang, "Improved flop tray-based design implementation for power reduction," Proc. ICCAD, Nov. 2018, pp. 1–8.


* **Effective Mean-Shift Clustering**: Y. Chang, T.-W. Lin, I. H.-R. Jiang, and G.-J. Nam, "Graceful register clustering by effective mean shift algorithm for power and timing balancing" in Proc. ISPD, Apr, 2019, pp. 11–18. ([GitHub](https://github.com/waynelin567/Register_Clustering])


The OpenROAD tool included in DATC RDF can support both MBFF clustering algorithsm. We included the example OpenROAD Tcl scripts for [FlopTray](./bin/mbff_clustering/flop-tray/run_openroad_flop_tray.tcl) and [Mean-Shift Clustering](./bin/mbff_clustering/mean-shift/run_openroad_mean_shift.tcl).



Adding Your Pont Tool Binaries into RDF Flow
---

You can add your own point tool in the RDF configurable flow.
First, put your point tool binary and necessary side files in the directory:

```bash
./bin/<stage>/<tool_name>
```

where `<stage>` is the target design stage, e.g., global placement or detailed routing, and `<tool_name>` is the name of your own tool.
Then, create the Python runner script, named:

```bash
./bin/<stage>/<tool_name>/rdf_<tool_name>.py
```

Then, you can add your tool in the flow configuration file, and RDF will call the Python runner script to launch your tool.


An example RDF Python runner script is shown below.

```python
import subprocess, os, sys, random, yaml, time
from subprocess import Popen, PIPE, CalledProcessError

sys.path.insert(0, '../../../src/stage.py')
from stage import *


def run(config, stage_dir, prev_out_dir, user_parms, write_run_scripts=False):
    triton_route = TritonRouteRunner(config, stage_dir, prev_out_dir, user_parms)
    triton_route.write_run_scripts()

    if not write_run_scripts:
        triton_route.run()


class TritonRouteRunner(Stage):
    def __init__(self, config, stage_dir, prev_out_dir, user_parms):
        super().__init__(config, stage_dir, prev_out_dir, user_parms)

        self.lef_mod = "{}/merged_padded_spacing.lef".format(self.lib_dir)
        self.in_guide = "{}/{}.guide".format(self.prev_out_dir, self.design_name)

    def write_run_scripts(self):
        self._write_parm_file()

        cmds = list()
        cmd = "cd {};".format(self.stage_dir)
        cmd += "${RDF_TOOL_BIN_PATH}/detail_route/TritonRoute/TritonRoute"
        cmd += " triton_route.parm"
        cmds.append(cmd)

        self.create_run_script_template()
        with open("{}/run.sh".format(self.stage_dir), 'a') as f:
            [f.write("{}\n".format(_)) for _ in cmds]

    def run(self):
        self._write_parm_file()
        self._run_triton_route()
        self._copy_final_output()

    def _write_parm_file(self):
        with open("{}/triton_route.parm".format(self.stage_dir), 'w') as f:
            f.write("lef:{}\n".format(self.lef_mod))
            f.write("def:{}\n".format(self.in_def))
            f.write("guide:{}\n".format(self.in_guide))
            f.write("output:tr.def\n")
            f.write("outputTA:test_TA.def\n")
            f.write("outputguide:output_guide.mod\n")
            f.write("outputMaze:maze.log\n")
            f.write("threads:32\n")
            f.write("cpxthreads:1\n")
            f.write("verbose:1\n")
            f.write("gap:0\n")
            f.write("timeout:3600\n")

    def _run_triton_route(self):
        cmd = "cd {};".format(self.stage_dir)
        cmd += "${RDF_TOOL_BIN_PATH}/detail_route/TritonRoute/TritonRoute"
        cmd += " triton_route.parm"

        with open("{}/out/{}.log".format(self.stage_dir, self.design_name), 'a') as f:
            f.write("\n")
            f.write("# Command: {}\n".format(cmd))
            f.write("\n")
            run_shell_cmd(cmd, f)

    def _copy_final_output(self):
        pass
```


Contributing Your Tool into DATC RDF
---

We welcome contributions to DATC RDF.



References
---

1. IEEE CEDA Design Automation Technical Committee, https://ieee-ceda.org/node/2591
1. J. Jung, I. H.-R. Jiang, G.-J. Nam, V. N. Kravets, L. Behjat, and Y.-L. Li, "OpenDesign Flow Database: The infrastructure for VLSI design and design automation research," Proc. ICCAD, Nov. 2016, pp. 42:1-42:6.
1. J. Jung, P.-Y. Lee, Y. Wu, N. K. Darav, I. H. Jiang, V. N. Kravets, L. Behjat, Y. Li,and G. Nam, "DATC RDF: Robust design flow database," Proc. ICCAD, Nov. 2017,pp. 872–873.
1. J. Jung, I. H.-R. Jiang, J. Chen, S.-T. Lin, Y.-L. Li, V. N. Kravets, and G.-J. Nam, "DATC RDF: An academic flow from logic synthesis to detailed routing," Proc.ICCAD, Nov. 2018, pp. 37:1–37:4.
1. J. Jung, I. H.-R. Jiang, J. Chen, S.-T. Lin, Y.-L. Li, V. N. Kravets, and G.-J. Nam, "DATC RDF: An open design flow from logic synthesis to detailed routing," Proc. Workshop on Open-Source EDA Technology (WOSET), Nov. 2018, pp. 6:1–6:4.
1. J. Chen, I. H.-R. Jiang, J. Jung, A. B. Kahng, V. N. Kravets, Y.-L. Li, S.-T. Lin andM. Woo, "DATC RDF-2019: Towards a complete academic reference design flow," Proc. ICCAD, Nov. 2019, pp. 1–6.

