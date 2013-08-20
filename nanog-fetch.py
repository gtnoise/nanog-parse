# Author: Arpit Gupta (glex.qsd@gmail.com)
# Author: Nick Feamster

import os,sys
months={'January': 1,'February': 2,'March': 3,'April': 4,'May': 5,'June': 6,
'July': 7, 'August': 8, 'September': 9, 'October': 10, 'November': 11, 'December': 12}
years=[2009,2010,2011,2012,2013]

starttime=['August',2013]
endtime=['August',2013]


def afterStart(month,year):
    if year>starttime[1]:
        return True
    elif year==starttime[1]:
        if months[month]>=months[starttime[0]]:
            return True
    else:
        return False
    

def beforeEnd(month,year):
    if year<endtime[1]:
        return True
    elif year==endtime[1]:
        if months[month]<=months[endtime[0]]:
            return True
    else:
        return False


def parse_listfile(listfile):
    lfile = open(listfile,'r')
    lst=[]
    for line in lfile.readlines():
        if line.startswith('<LI><A HREF='):
            lst.append(str(line.split('<LI><A HREF="')[1].split('">')[0]))
    #print lst
    return lst
            
def main():
    print 'start the nanog-fetch'
    for year in years:

        for month in months.keys():
            if afterStart(month,year) and beforeEnd(month,year):
                
                dirname=str(year)+'-'+month
                cmd = 'mkdir data/'+dirname
                #print cmd
                os.system('mkdir data/'+dirname)
                #print dirname
                baseUrl='http://mailman.nanog.org/pipermail/nanog'
                #print baseUrl+'/'+dirname+'/thread.html'
                listurl=baseUrl+'/'+dirname+'/thread.html'
                listfile='data/'+dirname+'/listfile.html'
                cmd="wget -O "+listfile+" "+listurl
                #print cmd
                os.system(cmd)
                #print "list url fetched"
                msglist = parse_listfile(listfile)
                for msg in msglist:
                    #print msg
                    msgfile='data/'+dirname+'/'+msg
                    msgurl=baseUrl+'/'+dirname+'/'+msg
                    #print msgurl
                    cmd="wget --quiet -O "+msgfile+" "+msgurl
                    print cmd
                    os.system(cmd)
            else:
                continue

if __name__ == "__main__":
    main()

