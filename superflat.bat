@echo off
pushd C:\Users\pix\IdeaProjects\superflat & dart bin/superflat.dart file:///%* & popd
if NOT ["%errorlevel%"]==["0"] pause