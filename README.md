# arabic-bible-bibliography
Data files and scripts for the Biblia Arabica bibliography project.

*2016-10-21 Notes about the Conversion Script and Results*

The conversion to Zotero was run on the Bibliography.odt file, which had been converted to TEI (bibliography-from-odt.xml) using OxGarage. 

1. Entries without “[#]” on the beginning. There were some entries in the original document that did not have a “[#]” on the beginning. It’s impossible to automatically distinguish these from the “abstract” paragraphs. I also don’t have an estimate of how many of these there are. In many cases, these would have been imported into the “abstract” field of another entry. There are 2 potential ways to clean this up—either editing the original document and sending it back to me to rerun the conversion script, or just using the original doc to spot which entries might be affected. 

2. Error tags. I’ve tried to have the converter insert tags to identify common problems with the conversion. These tags begin with “!” for easy identification. This will allow the research assistant to click on the tag, correct the relevant entries, and then remove the tag. Error tags include: “!no title” and “!missing title”, “!no author”, “!no date”, “!no pages”, “!no publisher”, “!no volume”, “!unknown type”, and “!uncaptured data”. The tag “!unknown type” means the converter could not parse whether the entry is a book, journal article, etc., so it should be reviewed. The tag “!uncaptured data” means the converter has put into a note item some text that the converter couldn’t find the right field for. 

3. Manuscript tags. All manuscript tags begin with “MS:” and then should have City, Location, Shelfmark. These will need quite a bit of refining, and the converter flagged ones it had trouble with by putting a ? on the beginning (“?MS:”). For your reference, there are 586 MS tags (some of which will still need cleanup) and 118 ?MS tags (all of which will need cleanup). 

4. Subject tags. These begin with “Subject:”. I was able to grab the lowest-level subject heading for most/all items, but I had no good way to grab higher-level ones. Thus, each entry currently has only 1 Subject tag. It shouldn’t be hard to add the higher-level subject tags using the lower-level ones. For instance, you can select “Subject: Ibn Qutayba” and then apply the label “Subject: Muslim Reception” to all of these at once. 

5. Encyclopedia articles are classified as book sections. This should be fairly easy to find and fix by just searching for the relevant terms, like “Encyclopaedia”. 

6. Series information is often weak or messy. It might be worth looking through all the entries that have series information. Also, I did not try to include any series editors. 

7. Titles that had italics inside them (instead of the whole title being italicized) were not processed correctly. There should not be many of these. For example: 
[#] Swanson, Mark, “Ibn Taymiyya and the Kitāb al-burhān. A Muslim controversialist responds to a ninth-century Arabic Christian apology,” in Haddad, Y.Y. and W.Z. Haddad (eds.), Christian-Muslim encounters, Gainesville, FL: University Press of Florida, 1995, 95-107.

8. Reprints were not captured and/or may have confused publisher/date info. These should be easy to add/correct by searching the original doc for “reprint”. 

9. There were a few types of data that occur rarely enough that I did not try to capture them. These should not be hard to find and add manually with simple searches:
- URLs
- translators
- language of item
- number of volumes