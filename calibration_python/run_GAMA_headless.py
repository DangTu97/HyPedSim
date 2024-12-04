import os
os.chdir("/Applications/Gama.app/Contents/headless")
#os.system("sh ./gama-headless.sh ./samples/predatorPrey2.xml ./test")
# os.system("sh ./gama-headless.sh ./samples/roadTraffic.xml ./output-folder")
#os.system("sh ./gama-headless.sh ./samples/calibration.xml ./test")
#os.system("sh ./gama-headless.sh ./samples/test_XYZT.xml ./test")

command = "sh ./gama-headless.sh ./samples/calibration_parallel_xml/calibration.xml ./test"
os.system(command)