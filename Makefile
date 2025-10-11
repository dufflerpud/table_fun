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

OUTPUT_TYPES=$(basename $(notdir $(wildcard handlers/*.pl)))
INPUT_FILES=$(notdir $(wildcard inputs/*.*) )
TEST_OUTPUTS=$(addprefix $(RESDIR)/,$(foreach output,$(OUTPUT_TYPES),$(foreach input,$(INPUT_FILES),$(input).$(output))))
vars:
		@echo "INPUT_FILES=$(INPUT_FILES)"
		@echo "OUTPUT_TYPES=$(OUTPUT_TYPES)"
		@echo "TEST_OUTPUTS=$(TEST_OUTPUTS)"
		@echo "RESDIR=$(RESDIR)"

#%:
#		@echo "Invoking std_$@ rule:"
#		@$(MAKE) std_$@ ORIGINAL_TARGET=$@

test:		$(TEST_OUTPUTS)

$(RESDIR)/%:
		@[ -d $(RESDIR) ] || mkdir -p $(RESDIR)
		$(BINDIR)/table_fun -if inputs/$(notdir $(basename $@)) -of $@

results/%:
		@[ -d $(RESDIR) ] || mkdir -p $(RESDIR)
		$(BINDIR)/table_fun -if inputs/$(notdir $(basename $@)) -of $@
