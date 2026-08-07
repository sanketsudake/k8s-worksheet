.PHONY: pdf clean

pdf:
	python3 build/build.py

clean:
	rm -rf dist
