#! /bin/bash

LANGUAGE=$(kdialog --getexistingdirectory ~/cityapp/scripts/shared/messages/ --title "Select language")
echo $LANGUAGE > ~/cityapp/scripts/shared/variables/lang

exit
