#! /bin/bash
# version 1.0
# CityApp maintenance
# Select language for CityApp messages
# 2020. január 22.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany


LANGUAGE=$(kdialog --getexistingdirectory ~/cityapp/scripts/shared/messages/ --title "Select language")
echo $LANGUAGE > ~/cityapp/scripts/shared/variables/lang

exit
