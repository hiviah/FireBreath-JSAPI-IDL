.PHONY: all example doc

all: example

example: 
	(cd example/ && python ../JSAPI_IDL_compiler.py FireBreath_JSAPI_IDL_example.yaml)

doc: README.html

README.html: README.md
	redcarpet $< > $@

