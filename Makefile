# Archive all inside .build/

.PHONY: all clean

all:
	bash Resources/DevKit/scripts/archive.all.sh

clean:
	rm -rf .build/
