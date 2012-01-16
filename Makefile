#!/use/bin/gmake -f

CWD = $(shell pwd)
CPD = ln -s
CPR = ln -s
BIN_DIR = usr/bin
LIB_DIR = usr/lib
ETC_DIR = etc

build:

install:
	@$(MAKE) DEB_BUILD=1 CPD='cp -d' CPR='cp -r' deploy

clean:

deploy: deploy-clean  deploy-dirs deploy-files

deploy-dirs: deploy-clean
	@echo "Deploy dirs..."
	@test -d $(DESTDIR)/$(BIN_DIR) || mkdir -p $(DESTDIR)/$(BIN_DIR)
	@test -d $(DESTDIR)/$(LIB_DIR) || mkdir -p $(DESTDIR)/$(LIB_DIR)
	@test -d $(DESTDIR)/$(ETC_DIR) || mkdir -p $(DESTDIR)/$(ETC_DIR)

deploy-files: deploy-dirs
	@echo "Deploy files..."
	@$(CPD) $(CWD)/$(BIN_DIR)/* $(DESTDIR)/$(BIN_DIR)/
	@$(CPR) $(CWD)/$(LIB_DIR)/nbld $(DESTDIR)/$(LIB_DIR)/
	@$(CPD) $(CWD)/$(ETC_DIR)/* $(DESTDIR)/$(ETC_DIR)/

ifndef DEB_BUILD
deploy-clean:
	@echo "Cleaning up before deploy..."
	@rm -rf $(DESTDIR)/$(LIB_DIR)/nbld
	@for file in `ls -1 $(CWD)/$(BIN_DIR)/* | sed -e 's|$(CWD)/$(BIN_DIR)/||'`; do \
		rm -f $(DESTDIR)/$(BIN_DIR)/$$file; \
	done
	@for file in `ls -1 $(CWD)/$(ETC_DIR)/* | sed -e 's|$(CWD)/$(ETC_DIR)/||'`; do \
		rm -f $(DESTDIR)/$(ETC_DIR)/$$file; \
	done

else
deploy-clean:
endif

.PHONY: build clean install deploy deploy-dirs deploy-files

