xquery version "3.0";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace z="http://www.zotero.org/namespaces/export#";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace vcard="http://nwalsh.com/rdf/vCard#";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace bib="http://purl.org/net/biblio#";
declare namespace dcterms="http://purl.org/dc/terms/";
declare namespace prism="http://prismstandard.org/namespaces/1.2/basic/";
declare namespace link="http://purl.org/rss/1.0/modules/link/";
declare namespace functx = "http://www.functx.com";
declare function functx:escape-for-regex
  ( $arg as xs:string? )  as xs:string {

   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;

let $doc := doc('biblia-arabica-zotero-export.rdf')
let $shelfmarks := distinct-values($doc//dc:subject[starts-with(.,'MS:')])
let $sections-all := $doc//dc:subject[starts-with(.,'Section:')]
let $shelfmark-revisions := doc('biblia-arabica-mss-tags-revised.xml')/JSON/rows
let $shelfmarks-revised := distinct-values($shelfmark-revisions/Revised_Tag/normalize-space())
let $collections := 
    for $shelfmark in $shelfmarks-revised
    return replace($shelfmark,'MS:\s*([^=\(]*),.*$','$1')
let $collections-distinct := distinct-values($collections)
(:let $collections-distinct-regex := string-join($collections-distinct,"|"):)
let $shelfmarks-with-sections := 
    for $shelfmark in $shelfmarks-revised
        let $shelfmarks-raw := $shelfmark-revisions[normalize-space(Revised_Tag)=$shelfmark]/Raw_Tag/normalize-space()
        (:let $shelfmark-no-collection := 
            replace(
                $shelfmark, 
                'MS:\s*[^=]*,\s*',
                ''):)
        let $sections := $sections-all[./following-sibling::dc:subject/normalize-space()=$shelfmarks-raw or ./preceding-sibling::dc:subject/normalize-space()=$shelfmarks-raw]
        let $sections-distinct := string-join(distinct-values($sections),', ')
        let $sections-labels-removed := replace($sections-distinct, 'Section:\s+','')
        
    return if ($sections-labels-removed) then 
        concat($shelfmark,' (',$sections-labels-removed,')')
        else concat($shelfmark, ' (undesignated) ')
        
let $collections-with-shelfmarks := 
    for $collection in $collections-distinct
    let $shelfmarks-in-collection := $shelfmarks-with-sections[matches(.,concat('MS:\s*',$collection))]
    let $shelfmarks-in-collection-shortened := 
        for $shelfmark in $shelfmarks-in-collection
        return 
            replace(
                $shelfmark,
                concat(
                    'MS:\s*',
                    functx:escape-for-regex($collection),
                    ',\s*'),
                '')
    return 
        (element h2 {$collection, 
        concat('(',count($shelfmarks-in-collection-shortened),' manuscript[s])')},
        element p {string-join($shelfmarks-in-collection-shortened,', ')})

return 
<html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title>Manuscript references related to Arabic Bible translations recorded in the Bibliography of the Arabic Bible</title>
            </head>
            <body>
                <h1>Manuscript references related to Arabic Bible translations
                ({count($shelfmarks-revised)} manuscripts)</h1>
                <p>The following list of collections and shelfmarks reflects manuscripts mentioned in secondary literature 
                about Arabic Bible translations (not including catalogues), as recorded in the 
                <i><a href="https://biblia-arabica.com/bibl">Bibliography of the Arabic Bible</a></i> (Ronny Vollandt, general editor). 
                Biblical sections in parentheses, such as "(Pentateuch)," 
                indicate which parts of the Bible have been tagged for the literature about the manuscript. They indicate which 
                biblical texts the bibliographic item discusses and may or may not reflect which texts the manuscript contains.
                Manuscripts related to the New Testament are included here for completeness.</p>
                <p>Each manuscript shelfmark listed here has corresponding secondary literature describing it, detailed in the latest 
                pre-publication version of the <i>Bibliography of the Arabic Bible</i> (1,758 items). NB: this list may not be fully 
                standardized, since some of the entries it is based on have not yet been fully edited for publication.</p>
                <p>Last updated {current-date()}.</p>
                {$collections-with-shelfmarks}
            </body>
        </html> 

