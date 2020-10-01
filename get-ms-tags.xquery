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

let $doc := doc('biblia-arabica-zotero-export.rdf')
let $shelfmarks := distinct-values($doc//dc:subject[starts-with(.,'MS:')])

return string-join($shelfmarks,'
')
(:for $shelfmark in $shelfmarks 
    let $sections := $doc//dc:subject[starts-with(.,'Section:') and (./following-sibling::dc:subject=$shelfmark or ./preceding-sibling::dc:subject=$shelfmark)]
    let $sections-distinct := string-join(distinct-values($sections),', ')
    let $sections-labels-removed := replace($sections-distinct, 'Section:\s+','')
    return if ($sections-labels-removed) then 
        concat($shelfmark,' (',$sections-labels-removed,')')
        else concat($shelfmark, ' (undesignated) '):)