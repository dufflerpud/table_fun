#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
PROJECTSDIR?=$(shell echo $(CURDIR) | sed -e 's+/projects/.*+/projects+')
include $(PROJECTSDIR)/common/Makefile.std

OUTPUT_TYPES=$(shell $(BINDIR)/table_fun -show=outputs)
INPUT_FILES=$(notdir $(wildcard tests/*.*) )
TEST_OUTPUTS=$(addprefix $(RESDIR)/,$(foreach output,$(OUTPUT_TYPES),$(foreach input,$(INPUT_FILES),$(input).$(output))))

test:
		@echo "output_types=$(OUTPUT_TYPES)"
		@echo "input_files=$(INPUT_FILES)"
		@echo "test_outputs=$(TEST_OUTPUTS)"
		$(MAKE) $(TEST_OUTPUTS)

fresh:
		git pull
		sudo $(MAKE) install

$(RESDIR)/%:
		@[ -d $(RESDIR) ] || mkdir -p $(RESDIR)
		$(BINDIR)/table_fun -if tests/$(notdir $(basename $@)) -of $@

results/%:
		@[ -d $(RESDIR) ] || mkdir -p $(RESDIR)
		$(BINDIR)/table_fun -if tests/$(notdir $(basename $@)) -of $@

%:
		@echo "Invoking std_$@ rule:"
		@$(MAKE) std_$@ ORIGINAL_TARGET=$@
