from selenium import webdriver 
from optparse import OptionParser
from selenium.webdriver.chrome.options import Options
import urllib
import requests
import os, sys

URL_LOCATE_PREX = "https://www.aitaotu.com/guonei/"
DEST_ROOT       = "/Users/ddk/Downloads/img/"

def download(serial):
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--window-size=1920,1080")
    driver = webdriver.Chrome(executable_path="/usr/local/chromedriver", chrome_options=chrome_options)

    dest_path = DEST_ROOT + serial
    if not os.path.exists(dest_path): 
        os.mkdir(dest_path)
    
    url_local = URL_LOCATE_PREX + serial + ".html"
    driver.get(url_local)
    print("get path: " + url_local)

    total = int(driver.find_element_by_class_name("totalpage").text)

    section = driver.find_elements_by_xpath("//div[@id='big-pic']/p/a/img")
    section_size = len(section)
    
    url_img = driver.find_element_by_xpath("//div[@id='big-pic']/p/a/img").get_attribute("src")
    url_img_prex = url_img[0:url_img.rfind("/")+1]

    print( "total: " + str(total) )
    print( "section: " + str(section_size) )
    print( "img_prex: " + url_img_prex )

    img_index = 1
    for i in range(1, total + 1):
        if i != 1:
            url_local = URL_LOCATE_PREX + serial + "_" + str(i) + ".html"
        driver.get(url_local)
        for j in range(0, section_size): 
            url_img = url_img_prex + "{:0>2d}".format(img_index) + ".jpg"
            driver.get(url_img)
            img_file = dest_path + "/" +  str(img_index) + ".png"
            driver.save_screenshot(img_file)
            print("save img as " + img_file)
            img_index = img_index + 1
    driver.close()

SIZE = len(sys.argv)
for index in range(1, SIZE):
    download(sys.argv[index])
