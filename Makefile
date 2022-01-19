# To list all targets:
#   make list
#
# High-level make targets:
#   text              Build all Inter Text fonts (default target)
#   display           Build all Inter Display fonts
#   all               Build everything
#   web               Build all web fonts
#   var               Build all variable fonts
#   test              Run all test (builds fonts if needed)
#   zip               Build a complete ZIP archive of all fonts
#   zip_text          Build a complete ZIP archive of all Inter Text fonts
#   zip_display       Build a complete ZIP archive of all Inter Display fonts
#   install           Build and install all OTF files (macOS only)
#
# Style-specific targets:
#   STYLE_otf         Build OTF file for STYLE into FONTDIR/const
#   STYLE_ttf         Build TTF file for STYLE into FONTDIR/const
#   STYLE_ttf_hinted  Build TTF file for STYLE with hints into
#                     FONTDIR/const-hinted
#   STYLE_web         Build WOFF files for STYLE into FONTDIR/const
#   STYLE_web_hinted  Build WOFF files for STYLE with hints into
#                     FONTDIR/const-hinted
#   STYLE_check       Build & check OTF and TTF files for STYLE
#
# "build" directory output structure:
#   fonts
#     const
#     const-hinted
#     var
#
FONTDIR = build/fonts

default: text
all:     text display

# all fonts of given variant
text:    all_otf_text     all_ttf_text     all_ttf_text_hinted     all_var_text     web_text
display: all_otf_display  all_ttf_display  all_ttf_display_hinted  all_var_display  web_display

# all fonts of a certain type
all_otf:     all_otf_text  all_otf_display
all_ttf:     all_ttf_text  all_ttf_display  all_ttf_text_hinted  all_ttf_display_hinted

web:         web_text  web_display
web_text:    all_web_text     all_web_hinted_text
web_display: all_web_display  all_web_hinted_display

var: all_var_text  all_var_display
var_text:    $(FONTDIR)/var/Inter.var.woff2 $(FONTDIR)/var/Inter.var.ttf $(FONTDIR)/var/Inter-V.var.ttf
var_display: $(FONTDIR)/var/InterDisplay.var.woff2 $(FONTDIR)/var/InterDisplay.var.ttf $(FONTDIR)/var/InterDisplay-V.var.ttf
all_var_text: \
	$(FONTDIR)/var/Inter.var.ttf \
	$(FONTDIR)/var/Inter.var.woff2 \
	$(FONTDIR)/var/Inter-V.var.ttf \
	$(FONTDIR)/var/Inter-V.var.woff2 \
	$(FONTDIR)/var/Inter-roman.var.ttf \
	$(FONTDIR)/var/Inter-roman.var.woff2 \
	$(FONTDIR)/var/Inter-italic.var.ttf \
	$(FONTDIR)/var/Inter-italic.var.woff2
all_var_display: \
	$(FONTDIR)/var/InterDisplay.var.ttf \
	$(FONTDIR)/var/InterDisplay.var.woff2 \
	$(FONTDIR)/var/InterDisplay-V.var.ttf \
	$(FONTDIR)/var/InterDisplay-V.var.woff2 \
	$(FONTDIR)/var/InterDisplay-roman.var.ttf \
	$(FONTDIR)/var/InterDisplay-roman.var.woff2 \
	$(FONTDIR)/var/InterDisplay-italic.var.ttf \
	$(FONTDIR)/var/InterDisplay-italic.var.woff2

.PHONY: all  all_otf  all_ttf  text  display
.PHONY: web  web_text  web_display
.PHONY: var  var_text  var_display  all_var_text  all_var_display

# Hinted variable font disabled. See https://github.com/rsms/inter/issues/75
# all_var_hinted: $(FONTDIR)/var-hinted/Inter.var.ttf $(FONTDIR)/var-hinted/Inter.var.woff2

BIN := $(PWD)/build/venv/bin
export PATH := $(BIN):$(PATH)

# list make targets
# We copy the Makefile (first in MAKEFILE_LIST) and disable the include to only list
# primary targets, avoiding the generated targets.
.PHONY: list  list_all
list:
	@mkdir -p build/etc \
	&& cat $(firstword $(MAKEFILE_LIST)) \
	 | sed 's/include /#include /g' > build/etc/Makefile-list \
	&& $(MAKE) -pRrq -f build/etc/Makefile-list : 2>/dev/null \
	 | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' \
	 | sort \
	 | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
# list_all is like list, but includes generated targets
list_all:
	@$(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null \
	 | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' \
	 | sort \
	 | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

# generated.make is automatically generated by init.sh and defines depenencies for
# all styles and alias targets
include build/etc/generated.make


# WOFF2 from TTF
build/%.woff2: build/%.ttf
	$(BIN)/woff2_compress "$<"

# WOFF from TTF
build/%.woff: build/%.ttf
	$(BIN)/ttf2woff -O -t woff "$<" "$@"



# VF OTF from UFO
$(FONTDIR)/var/Inter.var.ttf: $(all_ufo_masters_text) version.txt
	@mkdir -p "$(dir $@)"
	misc/fontbuild compile-var -o $@ $(FONTBUILD_FLAGS) build/ufo/Inter.designspace
	$(BIN)/gftools fix-unwanted-tables -t MVAR $@
	$(BIN)/gftools fix-dsig --autofix $@

$(FONTDIR)/var/Inter-V.var.ttf: $(FONTDIR)/var/Inter.var.ttf
	misc/fontbuild rename --family "Inter V" -o $@ $<

$(FONTDIR)/var/Inter-%.var.ttf: build/ufo/Inter-%.designspace $(all_ufo_masters_text) version.txt
	@mkdir -p "$(dir $@)"
	misc/fontbuild compile-var -o $@ $(FONTBUILD_FLAGS) $<
	misc/tools/fix-vf-meta.py $@
	$(BIN)/gftools fix-unwanted-tables -t MVAR $@
	$(BIN)/gftools fix-dsig --autofix $@


$(FONTDIR)/var/InterDisplay.var.ttf: $(all_ufo_masters_display) version.txt
	@mkdir -p "$(dir $@)"
	misc/fontbuild compile-var -o $@ $(FONTBUILD_FLAGS) build/ufo/InterDisplay.designspace
	$(BIN)/gftools fix-unwanted-tables -t MVAR $@
	$(BIN)/gftools fix-dsig --autofix $@

$(FONTDIR)/var/InterDisplay-V.var.ttf: $(FONTDIR)/var/InterDisplay.var.ttf
	misc/fontbuild rename --family "Inter Display V" -o $@ $<

$(FONTDIR)/var/InterDisplay-%.var.ttf: build/ufo/InterDisplay-%.designspace $(all_ufo_masters_display) version.txt
	@mkdir -p "$(dir $@)"
	misc/fontbuild compile-var -o $@ $(FONTBUILD_FLAGS) $<
	misc/tools/fix-vf-meta.py $@
	$(BIN)/gftools fix-unwanted-tables -t MVAR $@
	$(BIN)/gftools fix-dsig --autofix $@


# OTF/TTF from UFO
$(FONTDIR)/const/Inter%.otf: build/ufo/Inter%.ufo version.txt
	@mkdir -p "$(dir $@)"
	misc/fontbuild compile -o $@ $(FONTBUILD_FLAGS) build/ufo/Inter$*.ufo

$(FONTDIR)/const/Inter%.ttf: build/ufo/Inter%.ufo version.txt
	@mkdir -p "$(dir $@)"
	misc/fontbuild compile -o $@ $(FONTBUILD_FLAGS) build/ufo/Inter$*.ufo


# DESIGNSPACE from GLYPHS
build/ufo/Inter-roman.designspace: build/ufo/Inter.designspace
build/ufo/Inter-italic.designspace: build/ufo/Inter.designspace
build/ufo/Inter.designspace: src/Inter.glyphs
	@mkdir -p build/ufo
	misc/fontbuild glyphsync -o build/ufo src/Inter.glyphs
build/ufo/InterDisplay-roman.designspace: build/ufo/InterDisplay.designspace
build/ufo/InterDisplay-italic.designspace: build/ufo/InterDisplay.designspace
build/ufo/InterDisplay.designspace: src/InterDisplay.glyphs
	@mkdir -p build/ufo
	misc/fontbuild glyphsync -o build/ufo src/InterDisplay.glyphs


# short-circuit Make for performance
src/Inter.glyphs:
	@true
src/InterDisplay.glyphs:
	@true

# make sure intermediate files are not gc'd by make
.PRECIOUS: build/ufo/Inter-*.designspace build/ufo/InterDisplay-*.designspace

designspace: build/ufo/Inter.designspace build/ufo/InterDisplay.designspace
.PHONY: designspace


# features
src/features: $(wildcard src/features/*)
	@touch "$@"
	@true
build/ufo/features: src/features
	@mkdir -p build/ufo
	@rm -f build/ufo/features
	@ln -s ../../src/features build/ufo/features

# make sure intermediate UFOs are not gc'd by make
.PRECIOUS: build/ufo/Inter-%.ufo

# Note: The seemingly convoluted dependency graph above is required to
# make sure that glyphsync and instancegen are not run in parallel.


# hinted TTF files via autohint
$(FONTDIR)/const-hinted/%.ttf: $(FONTDIR)/const/%.ttf
	mkdir -p "$(dir $@)"
	$(BIN)/ttfautohint --windows-compatibility --adjust-subglyphs --no-info "$<" "$@"

# python -m ttfautohint --fallback-stem-width=256 --no-info "$<" "$@"

# $(FONTDIR)/var-hinted/%.ttf: $(FONTDIR)/var/%.ttf
# 	mkdir -p "$(dir $@)"
# 	ttfautohint --fallback-stem-width=256 --no-info "$<" "$@"

# make sure intermediate TTFs are not gc'd by make
.PRECIOUS: $(FONTDIR)/const/%.ttf
.PRECIOUS: $(FONTDIR)/const/%.otf
.PRECIOUS: $(FONTDIR)/const-hinted/%.ttf
.PRECIOUS: $(FONTDIR)/var/%.var.ttf



# test runs all tests
# Note: all_check_const is generated by init.sh and runs "fontbuild checkfont"
# on all otf and ttf files.
test: test_text  test_display

test_text: check_text \
           build/fbreport-text-const.txt \
           build/fbreport-text-var1.txt \
           build/fbreport-text-var2.txt
  @echo "$(@): OK"

test_display: check_display \
              build/fbreport-display-const.txt \
              build/fbreport-display-var1.txt \
              build/fbreport-display-var2.txt
  @echo "$(@): OK"

# FBAKE_ARGS are common args for all fontbakery targets
FBAKE_ARGS := check-universal \
              --no-colors \
              --no-progress \
              --loglevel WARN \
              --succinct \
              -j \
              -x com.google.fonts/check/dsig \
              -x com.google.fonts/check/unitsperem \
              -x com.google.fonts/check/family/win_ascent_and_descent \
              -x com.google.fonts/check/fontbakery_version

FBAKE_STATIC_ARGS := $(FBAKE_ARGS) -x com.google.fonts/check/family/underline_thickness
FBAKE_VAR_ARGS    := $(FBAKE_ARGS) -x com.google.fonts/check/STAT_strings

# static text family
build/fbreport-text-const.txt: $(wildcard $(FONTDIR)/const/Inter-*.otf)
	@echo "fontbakery check-universal Inter-*.otf > $(@) ..."
	@$(BIN)/fontbakery $(FBAKE_STATIC_ARGS) $^ > $@ || \
	  (cat $@; echo "report at $@"; touch -m -t 199001010000 $@; exit 1)
	@echo "fontbakery check-universal Inter-*.otf OK"

# multi-axis VF text family
build/fbreport-text-var2.txt: $(FONTDIR)/var/Inter.var.ttf
	@echo "fontbakery check-universal Inter.var.ttf > $(@) ..."
	@$(BIN)/fontbakery $(FBAKE_VAR_ARGS) $^ > $@ || \
	  (cat $@; echo "report at $@"; touch -m -t 199001010000 $@; exit 1)
	@echo "fontbakery check-universal Inter.var.ttf"

# single-axis VF text family
build/fbreport-text-var1.txt: $(wildcard $(FONTDIR)/var/Inter-*.var.ttf)
	@echo "fontbakery check-universal Inter-*.var.ttf > $(@) ..."
	@$(BIN)/fontbakery $(FBAKE_VAR_ARGS) $^ > $@ || \
	  (cat $@; echo "report at $@"; touch -m -t 199001010000 $@; exit 1)
	@echo "fontbakery check-universal Inter-*.var.ttf"


# static display family
build/fbreport-display-const.txt: $(wildcard $(FONTDIR)/const/InterDisplay-*.otf)
	@echo "fontbakery check-universal InterDisplay-*.otf > $(@) ..."
	@$(BIN)/fontbakery $(FBAKE_STATIC_ARGS) $^ > $@ || \
	  (cat $@; echo "report at $@"; touch -m -t 199001010000 $@; exit 1)
	@echo "fontbakery check-universal InterDisplay-*.otf"

# multi-axis VF display family
build/fbreport-display-var2.txt: $(FONTDIR)/var/InterDisplay.var.ttf
	@echo "fontbakery check-universal InterDisplay.var.ttf > $(@) ..."
	@$(BIN)/fontbakery $(FBAKE_VAR_ARGS) $^ > $@ || \
	  (cat $@; echo "report at $@"; touch -m -t 199001010000 $@; exit 1)
	@echo "fontbakery check-universal InterDisplay.var.ttf"

# single-axis VF display family
build/fbreport-display-var1.txt: $(wildcard $(FONTDIR)/var/InterDisplay-*.var.ttf)
	@echo "fontbakery check-universal InterDisplay-*.var.ttf > $(@) ..."
	@$(BIN)/fontbakery $(FBAKE_VAR_ARGS) $^ > $@ || \
	  (cat $@; echo "report at $@"; touch -m -t 199001010000 $@; exit 1)
	@echo "fontbakery check-universal InterDisplay-*.var.ttf"

# check does the same thing as test, but without any dependency checks, meaning
# it will check whatever font files are already built.
check_text: $(wildcard $(FONTDIR)/const/Inter-*.ttf) \
            $(wildcard $(FONTDIR)/const/Inter-*.otf) \
            $(wildcard $(FONTDIR)/const/Inter-*.woff2) \
            $(wildcard $(FONTDIR)/var/Inter-*.var.ttf) \
            $(wildcard $(FONTDIR)/var/Inter-*.var.woff2) \
            $(FONTDIR)/var/Inter.var.ttf \
            $(FONTDIR)/var/Inter.var.woff2
	misc/fontbuild checkfont $^
	@echo "$(@): OK"

check_display: $(wildcard $(FONTDIR)/const/InterDisplay-*.ttf) \
               $(wildcard $(FONTDIR)/const/InterDisplay-*.otf) \
               $(wildcard $(FONTDIR)/const/InterDisplay-*.woff2) \
               $(wildcard $(FONTDIR)/var/InterDisplay-*.var.ttf) \
               $(wildcard $(FONTDIR)/var/InterDisplay-*.var.woff2) \
               $(FONTDIR)/var/InterDisplay.var.ttf \
               $(FONTDIR)/var/InterDisplay.var.woff2
	misc/fontbuild checkfont $^ \
	@echo "$(@): OK"

check_pedantic: $(FONTDIR)/var/Inter.var.ttf
	$(BIN)/fontbakery check-universal --dark-theme --loglevel WARN -j \
		-x com.google.fonts/check/unitsperem \
		$^

.PHONY: test test_text test_display check_text check_display check_pedantic




# samples renders PDF and PNG samples
samples: $(FONTDIR)/samples all_samples_pdf all_samples_png

$(FONTDIR)/samples/%.pdf: $(FONTDIR)/const/%.otf $(FONTDIR)/samples
	misc/tools/fontsample/fontsample -o "$@" "$<"

$(FONTDIR)/samples/%.png: $(FONTDIR)/const/%.otf $(FONTDIR)/samples
	misc/tools/fontsample/fontsample -o "$@" "$<"

$(FONTDIR)/samples:
	mkdir -p $@

.PHONY: samples


# load version, used by zip and dist
VERSION := $(shell cat version.txt)

# distribution zip files
ZIP_FILE_DIST := build/release/Inter-${VERSION}.zip

zip: all
	$(MAKE) -j8 test
	bash misc/makezip.sh -all -reveal-in-finder \
		"build/release/Inter-${VERSION}-$(shell git rev-parse --short=10 HEAD).zip"

zip_text: text
	$(MAKE) -j4 test_text
	bash misc/makezip.sh -text -reveal-in-finder \
		"build/release/Inter-${VERSION}-text-$(shell git rev-parse --short=10 HEAD).zip"

zip_display: display
	$(MAKE) -j4 test_display
	bash misc/makezip.sh -display -reveal-in-finder \
		"build/release/Inter-${VERSION}-display-$(shell git rev-parse --short=10 HEAD).zip"


dist_zip: dist_check dist_build
	$(MAKE) -j4 test_text
	bash misc/makezip.sh -text -reveal-in-finder "$(ZIP_FILE_DIST)"

dist_build: text
	misc/tools/versionize.py

dist_check:
	@echo "Creating distribution for version ${VERSION}"
	@if [ -f "${ZIP_FILE_DIST}" ]; then \
		echo "${ZIP_FILE_DIST} already exists. Bump version or remove the zip file to continue." >&2; \
		exit 1; \
	fi
	@echo "——————————————————————————————————————————————————————————————————"
	@echo ""
	@echo "     REMEMBER TO 'make clean' FIRST IF FONT FILES CHANGED"
	@echo ""
	@echo "——————————————————————————————————————————————————————————————————"

dist: dist_zip
	# Note: "display" dep is here since the "docs" target loosely depends on it
	$(MAKE) -j8 display
	$(MAKE) -j docs
	@echo "——————————————————————————————————————————————————————————————————"
	@echo ""
	@echo "Next steps:"
	@echo ""
	@echo "1) Commit & push changes"
	@echo ""
	@echo "2) Create new release with ${ZIP_FILE_DIST} at"
	@echo "   https://github.com/rsms/inter/releases/new?tag=v${VERSION}"
	@echo ""
	@echo "3) Bump version in version.txt (to the next future version)"
	@echo ""
	@echo "——————————————————————————————————————————————————————————————————"

.PHONY: zip zip_dist pre_dist dist



docs: docs_fonts
	$(MAKE) -j docs_info

docs_info: docs/_data/fontinfo.json \
           docs/lab/glyphinfo.json \
           docs/glyphs/metrics.json

docs_fonts: docs_fonts_text  docs_fonts_display


# TODO: re-enable this when we have figured out how to make subset VFs work
# with substitution features like ccmp.
# docs_fonts_pre:
# 	rm -rf docs/font-files
# 	mkdir docs/font-files $(FONTDIR)/subset
# 	python misc/tools/subset.py
# docs_fonts_text: docs_fonts_pre
# 	cp -a $(FONTDIR)/const/*.woff \
# 	      $(FONTDIR)/const/*.woff2 \
# 	      $(FONTDIR)/const/*.otf \
# 	      $(FONTDIR)/var/Inter.var.* \
# 	      $(FONTDIR)/var/InterDisplay.var.* \
# 	      $(FONTDIR)/var/Inter*-roman.var.* \
# 	      $(FONTDIR)/var/Inter*-italic.var.* \
# 	      $(FONTDIR)/subset/Inter-*.woff2 \
# 	      $(FONTDIR)/subset/Inter.*.woff2 \
# 	      docs/font-files/
# docs_fonts_display: docs_fonts_pre
# 	cp -a $(FONTDIR)/const/*.woff \
# 	      $(FONTDIR)/const/*.woff2 \
# 	      $(FONTDIR)/const/*.otf \
# 	      $(FONTDIR)/var/Inter.var.* \
# 	      $(FONTDIR)/var/InterDisplay.var.* \
# 	      $(FONTDIR)/var/Inter*-roman.var.* \
# 	      $(FONTDIR)/var/Inter*-italic.var.* \
# 	      $(FONTDIR)/subset/InterDisplay*.woff2 \
# 	      docs/font-files/

docs_fonts_pre:
	rm -rf docs/font-files
	mkdir docs/font-files

docs_fonts_text: docs_fonts_pre
	cp -a $(FONTDIR)/const/*.woff \
	      $(FONTDIR)/const/*.woff2 \
	      $(FONTDIR)/const/*.otf \
	      $(FONTDIR)/var/Inter.var.* \
	      $(FONTDIR)/var/InterDisplay.var.* \
	      $(FONTDIR)/var/Inter*-roman.var.* \
	      $(FONTDIR)/var/Inter*-italic.var.* \
	      docs/font-files/

docs_fonts_display: docs_fonts_pre
	cp -a $(FONTDIR)/const/*.woff \
	      $(FONTDIR)/const/*.woff2 \
	      $(FONTDIR)/const/*.otf \
	      $(FONTDIR)/var/Inter.var.* \
	      $(FONTDIR)/var/InterDisplay.var.* \
	      $(FONTDIR)/var/Inter*-roman.var.* \
	      $(FONTDIR)/var/Inter*-italic.var.* \
	      docs/font-files/

.PHONY: docs  docs_info  docs_fonts  docs_fonts_pre  docs_fonts_text  docs_fonts_display

docs/_data/fontinfo.json: docs/font-files/Inter-Regular.otf misc/tools/fontinfo.py
	misc/tools/fontinfo.py -pretty $< > docs/_data/fontinfo.json

docs/lab/glyphinfo.json: misc/tools/gen-glyphinfo.py build/ufo/Inter-Regular.ufo
	misc/tools/gen-glyphinfo.py -ucd misc/UnicodeData.txt build/ufo/Inter-Regular.ufo > $@

docs/glyphs/metrics.json: misc/tools/gen-metrics-and-svgs.py build/ufo/Inter-Regular.ufo
	misc/tools/gen-metrics-and-svgs.py build/ufo/Inter-Regular.ufo


# Helper target to download latest Unicode data. Nothing depends on this.
ucd_version := 12.1.0
update_UnicodeData:
	@echo "# Unicode $(ucd_version)" > misc/UnicodeData.txt
	curl '-#' "https://www.unicode.org/Public/$(ucd_version)/ucd/UnicodeData.txt" >> misc/UnicodeData.txt



# install targets
install_ttf: all_ttf_const
	@echo "Installing TTF files locally at ~/Library/Fonts/Inter"
	rm -rf ~/'Library/Fonts/Inter'
	mkdir -p ~/'Library/Fonts/Inter'
	cp -a $(FONTDIR)/const/*.ttf ~/'Library/Fonts/Inter'

install_ttf_hinted: all_ttf_hinted
	@echo "Installing autohinted TTF files locally at ~/Library/Fonts/Inter"
	rm -rf ~/'Library/Fonts/Inter'
	mkdir -p ~/'Library/Fonts/Inter'
	cp -a $(FONTDIR)/const-hinted/*.ttf ~/'Library/Fonts/Inter'

install_text_otf: all_otf_text
	@echo "Installing OTF files locally at ~/Library/Fonts/Inter"
	rm -rf ~/'Library/Fonts/Inter'
	mkdir -p ~/'Library/Fonts/Inter'
	cp -a $(FONTDIR)/const/Inter-*.otf ~/'Library/Fonts/Inter'

install_display_otf: all_otf_display
	@echo "Installing OTF files locally at ~/Library/Fonts/InterDisplay"
	rm -rf ~/'Library/Fonts/InterDisplay'
	mkdir -p ~/'Library/Fonts/InterDisplay'
	cp -a $(FONTDIR)/const/InterDisplay-*.otf ~/'Library/Fonts/InterDisplay'

install_text_var: $(FONTDIR)/var/Inter-V.var.ttf
	mkdir -p ~/'Library/Fonts/Inter'
	cp -a $@ ~/'Library/Fonts/Inter/Inter-V.ttf'

install_display_var: $(FONTDIR)/var/InterDisplay-V.var.ttf
	mkdir -p ~/'Library/Fonts/InterDisplay'
	cp -a $@ ~/'Library/Fonts/InterDisplay/InterDisplay-V.ttf'

install:         install_text  install_display
install_otf:     install_text_otf  install_display_otf
install_text:    install_text_otf  install_text_var
install_display: install_display_otf  install_display_var

# deprecated aliases
install_var_v:
	@echo 'Please use `make install_text_var` or `make install_display_var` instead.' >&2
	@exit 1

.PHONY: install_ttf install_ttf_hinted install_text_otf install_display_otf install_otf
.PHONY: install_text_var install_display_var install_var_v
.PHONY: install install_text install_display


# clean removes generated and built fonts in the build directory
clean:
	rm -rf build/tmp build/fonts build/ufo build/googlefonts

.PHONY: clean
