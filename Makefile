DSIM     := dsim
FILELIST := filelist.f
DSIM_OPTS := -sv -timescale 1ns/1ps -code-cov a +acc -f $(FILELIST)
DCREPORT := dcreport -out_dir reports metrics.db

TEST ?= test_register_access

.PHONY: all run wave clean

all:
	$(DSIM) $(DSIM_OPTS) +RUN_ALL
	$(DCREPORT)

run:
	$(DSIM) $(DSIM_OPTS) +TEST_CLASS=$(TEST)
	$(DCREPORT)

wave:
	$(DSIM) $(DSIM_OPTS) -dump-agg +TEST_CLASS=$(TEST) -waves $(TEST).vcd
	($(DCREPORT) || true)
	vcd2fst $(TEST).vcd $(TEST).fst
	rm $(TEST).vcd

clean:
	rm -rf dsim_work dsim.log dsim.env metrics.db reports *.vcd *.fst
