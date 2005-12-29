CXXFILES = $(wildcard *.cpp) $(wildcard tools/*.cpp)
CFILES = $(wildcard *.c) $(wildcard tools/*.c) 

SOURCES = $(CXXFILES) $(CFILES)
HEADERS = $(wildcard *.h)
EVERYTHING = $(SOURCES) $(HEADERS)

SOURCEDEPS = $(patsubst %.cpp,.deps/%.dpp,$(CXXFILES)) \
			 $(patsubst %.c,.deps/%.d,$(CFILES))

OPENC2E = \
	Agent.o \
	AgentRef.o \
	attFile.o \
	blkImage.o \
	bytecode.o \
	c16Image.o \
	Camera.o \
	caosScript.o \
	caosVar.o \
	caosVM_agent.o \
	caosVM_camera.o \
	caosVM_compound.o \
	caosVM_core.o \
	caosVM_creatures.o \
	caosVM_debug.o \
	caosVM_files.o \
	caosVM_flow.o \
	caosVM_genetics.o \
	caosVM_history.o \
	caosVM_input.o \
	caosVM_map.o \
	caosVM_motion.o \
	caosVM_net.o \
	caosVM.o \
	caosVM_ports.o \
	caosVM_resources.o \
	caosVM_scripts.o \
	caosVM_sounds.o \
	caosVM_time.o \
	caosVM_variables.o \
	caosVM_vehicles.o \
	caosVM_world.o \
	catalogue.lex.o \
	Catalogue.o \
	catalogue.tab.o \
	cmddata.o \
	CompoundAgent.o \
	CompoundPart.o \
	Creature.o \
	creaturesImage.o \
	dialect.o \
	fileSwapper.o \
	genomeFile.o \
	lex.mng.o \
	lexutil.o \
	lex.yy.o \
	main.o \
	Map.o \
	MetaRoom.o \
	mmapifstream.o \
	mngfile.o \
	mngparser.tab.o \
	PathResolver.o \
	physics.o \
	PointerAgent.o \
	pray.o \
	renderable.o \
	Room.o \
	Scriptorium.o \
	SDLBackend.o \
	SDL_gfxPrimitives.o \
	SimpleAgent.o \
	SkeletalCreature.o \
	streamutils.o \
	Vehicle.o \
	World.o

CFLAGS += -W -Wall -Wno-conversion -Wno-unused
XLDFLAGS=$(LDFLAGS) -lboost_filesystem $(shell sdl-config --libs) -lz -lm -lSDL_net -lSDL_mixer
COREFLAGS=-ggdb3 $(shell sdl-config --cflags) -I.
XCFLAGS=$(CFLAGS) $(COREFLAGS)
XCPPFLAGS=$(COREFLAGS) $(CPPFLAGS) $(CFLAGS)

default: openc2e tools/praydumper docs
all: openc2e tools/mngtest tools/filetests tools/praydumper docs tools/pathtest  tools/memstats

docs: docs.html

commandinfo.yml: $(wildcard caosVM_*.cpp) parsedocs.pl
	perl parsedocs.pl $(wildcard caosVM_*.cpp) > commandinfo.yml

docs.html: writehtml.pl commandinfo.yml
	perl writehtml.pl > docs.html

cmddata.cpp: commandinfo.yml writecmds.pl
	perl writecmds.pl commandinfo.yml > cmddata.cpp

lex.mng.cpp lex.mng.h: mng.l
	flex -+ --prefix=mng -d -o lex.mng.cpp --header-file=lex.mng.h mng.l

catalogue.lex.cpp catalogue.lex.h: catalogue.l catalogue.tab.hpp
	flex -+ --prefix=catalogue -d -o catalogue.lex.cpp --header-file=catalogue.lex.h catalogue.l 
	
mngfile.o: lex.mng.cpp

mngparser.tab.cpp mngparser.tab.hpp: mngparser.ypp
	bison -d --name-prefix=mng mngparser.ypp

catalogue.tab.cpp catalogue.tab.hpp: catalogue.ypp
	bison -d --name-prefix=cata catalogue.ypp

lex.yy.cpp lex.yy.h: caos.l
	flex -+ -d -o lex.yy.cpp --header-file=lex.yy.h caos.l

## lex.yy.h deps aren't detected evidently
caosScript.o: lex.yy.h lex.yy.cpp

## based on automake stuff
%.o: %.cpp
	mkdir -p .deps/`dirname $<` && \
	$(CXX) $(XCPPFLAGS) -MP -MD -MF .deps/$<.Td -o $@ -c $< && \
	mv .deps/$<.Td .deps/$<.d

%.o: %.c
	mkdir -p .deps/`dirname $<` && \
	$(CC) $(XCFLAGS) -MP -MD -MF .deps/$<.Td -o $@ -c $< && \
	mv .deps/$<.Td .deps/$<.d

include $(shell find .deps -name '*.d' -type f 2>/dev/null || true)
Catalogue.o: catalogue.lex.h catalogue.tab.hpp
lex.mng.o: mngparser.tab.hpp

openc2e: $(OPENC2E)
	$(CXX) $(XLDFLAGS) $(XCXXFLAGS) -o $@ $^

tools/filetests: tools/filetests.o genomeFile.o streamutils.o Catalogue.o
	$(CXX) $(XLDFLAGS) $(XCXXFLAGS) -o $@ $^

tools/praydumper: tools/praydumper.o pray.o
	$(CXX) $(XLDFLAGS) $(XCXXFLAGS) -o $@ $^

tools/mngtest: tools/mngtest.o mngfile.o mngparser.tab.o lex.mng.o
	$(CXX) $(XLDFLAGS) $(XCXXFLAGS) -o $@ $^

tools/pathtest: tools/pathtest.o PathResolver.o
	$(CXX) $(XLDFLAGS) $(XCXXFLAGS) -o $@ $^

tools/memstats: tools/memstats.o $(patsubst main.o,,$(OPENC2E))
	$(CXX) $(XLDFLAGS) $(XCXXFLAGS) -o $@ $^

clean:
	rm -f *.o openc2e filetests praydumper tools/*.o
	rm -rf .deps
	rm -f commandinfo.yml lex.yy.cpp lex.yy.h lex.mng.cpp lex.mng.h mngparser.tab.cpp mngparser.tab.hpp cmddata.cpp
	rm -f tools/filetests tools/memstats tools/mngtest tools/pathtest tools/praydumper
	rm -f headerdeps.dot headerdeps.png

test: openc2e 
	perl -MTest::Harness -e 'runtests(glob("unittests/*.t"))'

headerdeps.dot: $(wildcard *.h) $(wildcard *.hpp) mngparser.tab.hpp catalogue.tab.hpp lex.mng.h lex.yy.h catalogue.lex.h
	tools/depgraph.sh $^ > $@

headerdeps.png: headerdeps.dot
	dot -Tpng -o $@ $^

.PHONY: clean all dep docs
