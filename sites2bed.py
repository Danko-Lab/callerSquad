import argparse
import sys

parser = argparse.ArgumentParser(description='read a sites.txt file')
parser.add_argument('sites', help='stdout of bcftools isec.')
args = parser.parse_args()
siteFile = args.sites # path to sites.txt file

try:
    siteF = open(siteFile)
except IOError:
    sys.exit('sites.txt file not found.')
outF = open(siteFile.replace('txt', 'bed'), 'a')
for site in siteF:
    parts = site.split('\t')
    chr = parts[0]
    start = str(int(parts[1]) - 1)
    end = parts[1]
    name = parts[2] + '/' + parts[3]
    score = parts[4]
    outF.write("\t".join([chr, start, end, name, score]))
outF.close()
siteF.close()
