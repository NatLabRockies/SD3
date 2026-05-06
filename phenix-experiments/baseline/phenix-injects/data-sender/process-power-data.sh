cp -rv /kafka-csvs /grid/

cd /grid; /usr/bin/python3 grid_analysis.py -r kafka-csvs -s baseline -o results
mv -v kafka-csvs/ results/
/usr/bin/tar -czvf grid_results.tgz results/ 