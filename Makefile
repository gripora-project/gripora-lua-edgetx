
VARIANT ?= obj
VERSION ?= 0.0.0

ZIPFILE ?= gripora-lua-edgetx-$(VARIANT)-$(VERSION).zip


.PHONY:	all files package clean

all:	files

files:
	@bin/build.sh $(VARIANT)

package:
	@bin/build.sh $(VARIANT) && \
		rm -f $(ZIPFILE) && \
		cd $(VARIANT) && \
		zip -q -r ../$(ZIPFILE) *

clean:
	@rm -rf obj test release snapshot $(VARIANT) gripora-*.zip

