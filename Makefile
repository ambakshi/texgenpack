# Makefile for texgenpack.

# Target directory when installing.
INSTALL_DIR = /usr/bin

CFLAGS = -std=gnu99 -Ofast
LFLAGS = -O
#CFLAGS = -std=gnu99 -ggdb
#LFLAGS = -ggdb
PKG_CONFIG_CFLAGS = `pkg-config --cflags gtk+-3.0`
PKG_CONFIG_LFLAGS = `pkg-config --libs gtk+-3.0`
# For MinGW with GTK installed, uncomment the following line.
#PNG_LIB_LOCATION = `pkg-config --libs gtk+-3.0`
SHARED_MODULE_OBJECTS = image.o compress.o mipmap.o file.o texture.o etc2.o dxtc.o astc.o bptc.o half_float.o \
	compare.o rgtc.o
TEXGENPACK_MODULE_OBJECTS = texgenpack.o calibrate.o
TEXVIEW_MODULE_OBJECTS = viewer.o gtk.o

all : texgenpack texview/texview

texgenpack : $(TEXGENPACK_MODULE_OBJECTS) $(SHARED_MODULE_OBJECTS)
	$(CC) $(LFLAGS) $(TEXGENPACK_MODULE_OBJECTS) $(SHARED_MODULE_OBJECTS) -o texgenpack -lm -lpng -lfgen -lpthread $(PNG_LIB_LOCATION)

texview/texview : $(TEXVIEW_MODULE_OBJECTS) $(SHARED_MODULE_OBJECTS)
	$(CC) $(LFLAGS) $(TEXVIEW_MODULE_OBJECTS) $(SHARED_MODULE_OBJECTS) -o texview/texview -lm -lpng -lfgen -lpthread $(PKG_CONFIG_LFLAGS)

install : texgenpack texview/texview
	install -m 0755 texgenpack $(INSTALL_DIR)/texgenpack
	install -m 0755 texview/texview $(INSTALL_DIR)/texview

clean :
	rm -f $(TEXGENPACK_MODULE_OBJECTS) $(TEXVIEW_MODULE_OBJECTS) $(SHARED_MODULE_OBJECTS)
	rm -f texgenpack
	rm -f texview/texview

gtk.o : gtk.c
	$(CC) -c $(CFLAGS) $(PKG_CONFIG_CFLAGS) gtk.c -o gtk.o

file.o : file.c
	$(CC) -c $(CFLAGS) $(PKG_CONFIG_CFLAGS) file.c -o file.o

.c.o :
	$(CC) -c $(CFLAGS) $< -o $@

.c.s :
	$(CC) -S $(CFLAGS) $< -o $@

dep:
	rm -f .depend
	make .depend

.depend:
	echo '# Module dependencies' >>.depend
	$(CC) -MM $(patsubst %.o,%.c,$(TEXGENPACK_MODULE_OBJECTS)) >>.depend
	$(CC) -MM $(patsubst %.o,%.c,$(TEXVIEW_MODULE_OBJECTS)) >>.depend
	$(CC) -MM $(patsubst %.o,%.c,$(SHARED_MODULE_OBJECTS)) >>.depend

include .depend

docker:
	docker build -t texgenpack .

kodim01.dds: docker kodim01.png
	rm -f kodim01.dds
	docker run -ti --rm -v `pwd`/kodim01.png:/tmp/kodim01.png -v `pwd`:/data:rw texgenpack --compress --format dxt1 /tmp/kodim01.png /data/kodim01.dds
