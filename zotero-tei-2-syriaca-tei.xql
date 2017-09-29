xquery version "3.0";

(:Convert TEI exported from Zotero to Syriaca TEI bibl records. 
    This script makes the following CHANGES to TEI exported from Zotero: 
     - Adds a biblia-arabica.com URI as an idno and saves each biblStruct as an individual file.
     - Uses the Zotero ID (manually numbered tag) to add an idno with @type='zotero'
     - Changes the biblStruct/@corresp to an idno with @type='URI'
     - Changes tags starting with 'Subject: ' to <note type="tag">Subject: ...</note> 
     - Changes 1 or more space-separated numbers contained in idno[@type='callNumber'] to WorldCat URIs 
     - Separates multiple ISBN numbers into multiple idno[@type='ISBN'] elements
     - Changes URLs into refs. If a note begins with 'Vol: http' or 'URL: http' these are also converted into 
        refs, with the volume number as the ref text node.
     - Changes biblScope units for volumes and pages to Syriaca norms. (These could be changed but if so 
        should be done across all bibl records.
     - Changes respStmts with resp='translator' to editor[@role='translator']
        :)
     
(: KNOWN ISSUES
    - If a bibl record already exists with the same Zotero ID, it is not overwritten, 
        but subject tags are added to the existing record. 
    - Subject tags (which contain the URI of a record which should cite the bibl) are merely 
        kept as note[@type='tag']. They should be further processed with an additional script
        to add them to the appropriate record. See add-citation-from-zotero-subject.xql
    - This script may produce duplicate subject tags. :)

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace syriaca = "http://syriaca.org";
declare namespace functx = "http://www.functx.com";

declare function syriaca:update-attribute($input-node as node()*,$attribute as xs:string,$attribute-value as xs:string)
as node()*
{
    for $node in $input-node
        return
            element {xs:QName(name($node))} {
                        $node/@*[name()!=$attribute], 
                        attribute {xs:QName($attribute)} {$attribute-value}, 
                        $node/node()}
};

let $bibls := collection("/db/apps/ba-data/data/bibl/tei/")/TEI/text/body/biblStruct
let $zotero-doc := doc("/db/apps/ba-working-data/zotero-tei-2017-09-29.xml")

(:    Set this to the number of the highest existing bibl record. If the eXist data is up-to-date and no bibl URIs have been reserved outside eXist, 
 : this can be left blank and will be automatically determined. :)
(: Re-enable if not assigning bibl ids using Zotero ids :)
(:let $max-bibl-id := ''

let $all-bibl-ids := 
    for $uri in $bibls/descendant-or-self::idno[starts-with(.,'http://biblia-arabica.com/bibl')]
    return number(replace($uri,'http://biblia-arabica.com/bibl/',''))
let $max-bibl-id-auto := max($all-bibl-ids):)

for $zotero-bibl at $i in $zotero-doc/listBibl/biblStruct
    

(:    let $bibl-id := ( if(string-length($max-bibl-id)) then $max-bibl-id else $max-bibl-id-auto + $i):)
    let $bibl-id := $zotero-bibl/note[@type='tags']/note[@type='tag' and matches(.,'ID:\s*\d+$')]/replace(text(),'ID:\s*','')
    let $ba-uri := concat('http://biblia-arabica.com/bibl/',$bibl-id)
    
(:    Adds a biblia-arabica.com URI :)
    let $ba-idno := <idno type='URI'>{$ba-uri}</idno>
    
    (:tags:)
(:    Uses the Zotero ID (manually numbered tag) to add an idno with @type='zotero':)
(: Re-enable here and in $all-idnos and $matching-bibl if Zotero ID is different from bibl ID. :)
(:    let $zotero-id := $zotero-bibl/note[@type='tags']/note[@type='tag' and matches(.,'^\d+$')]/text()
    let $zotero-idno := <idno type='zotero'>{$zotero-id}</idno>:)
    
(:    Changes the biblStruct/@corresp to an idno with @type='URI':)
    let $zotero-idno-uri := <idno type='URI'>{string($zotero-bibl/@corresp)}</idno>
    
(:    Grabs URI in tags prefixed by 'Subject: '. :)
    let $subject-uri := $zotero-bibl/note[@type='tags']/note[@type='tag' and matches(.,'^\s*Subject:\s*')]
    let $tags := $zotero-bibl/note[@type='tags']/note[@type='tag' and not(matches(.,'^\s*Subject:\s*'))]
    let $notes := $zotero-bibl/note[not(@type=('tags','abstract'))]
    let $abstract := $zotero-bibl/note[@type='abstract']
    
(:    Changes 1 or more space-separated numbers contained in idno[@type='callNumber'] to WorldCat URIs :)
    let $callNumbers := $zotero-bibl/idno[@type='callNumber']
    let $callNumber-idnos := 
        for $num in $callNumbers
        return
            if (matches($num/text(),'^([\d]\s*)+$')) then
                for $split-num in tokenize($num/text(), ' ')
                return <idno type='URI'>{concat('http://www.worldcat.org/oclc/',$split-num)}</idno>
            else $num
            
    let $issn-idnos := $zotero-bibl/idno[@type='ISSN']
    
(:    Separates multiple ISBN numbers into multiple idno[@type='ISBN'] elements :)
    let $isbns := tokenize(normalize-space($zotero-bibl/idno[@type='ISBN']/text()),'\s')
    let $isbn-idnos := 
        for $isbn in $isbns
        return <idno type='ISBN'>{$isbn}</idno>
        
    let $all-idnos := ($ba-idno,(:$zotero-idno,:)$zotero-idno-uri,$callNumber-idnos,$issn-idnos,$isbn-idnos)
    
(:    links to external resources:)
(:    Changes URLs into refs. If a note begins with 'Vol: http' or 'URL: http' these are also converted into 
    refs, with the volume number as the ref text node.:) 
    let $refs := 
        let $vol-regex := '^\s*[Vv][Oo][Ll]\.*\s*(\d+)\s*:\s*http.*'
        let $url-regex := '^\s*[Uu][Rr][Ll]*\s*:\s*http.*'
        for $url in $zotero-bibl//note[@type='url' or matches(.,$vol-regex) or matches(.,$url-regex)]
            let $link-text := if (matches($url, $vol-regex)) then replace($url,$vol-regex,'Vol. $1') else ()
            let $link := replace($url,'^[A-Za-z:\d\s\.]*(http.*).*?$','$1')
        return element ref {attribute target {$link}, $link-text}
        
(:    Changes biblScope units for volumes and pages to Syriaca norms. (These could be changed but if so 
        should be done across all bibl records. :)
    let $biblScopes-monogr-old := $zotero-bibl/monogr/imprint/biblScope
    let $biblScopes-monogr-new := 
        (syriaca:update-attribute($biblScopes-monogr-old[@unit='volume'], 'unit', 'vol'),
        $biblScopes-monogr-old[@unit!='volume' and @unit!='page'],
        syriaca:update-attribute($biblScopes-monogr-old[@unit='page'], 'unit', 'pp')
        )
    let $biblScopes-series-old := $zotero-bibl/series/biblScope
    let $biblScopes-series-new := 
        (syriaca:update-attribute($biblScopes-series-old[@unit='volume'], 'unit', 'vol'),
        $biblScopes-series-old[@unit!='volume']
        )
        
    (: respStmt :)
(:    Changes respStmts with resp='translator' to editor[@role='translator']. :)
    let $resps-analytic := $zotero-bibl/analytic/respStmt
    let $resps-monogr := $zotero-bibl/monogr/respStmt
    let $translators-analytic := 
        for $translator in $resps-analytic[resp='translator']/persName
        return element editor {attribute role {'translator'},$translator/node()}
    let $translators-monogr := 
        for $translator in $resps-monogr[resp='translator']/persName
        return element editor {attribute role {'translator'},$translator/node()}
        
        
(:    Reconstructs record using transformed data. :)
    let $analytic := $zotero-bibl/analytic
    let $tei-analytic :=
        if ($analytic) then
            <analytic>
                {$analytic/(author|editor),$translators-analytic}
                {$analytic/title}
                {$all-idnos[.!='']}
                {$refs}
            </analytic>
            else()
            
    let $monogr := $zotero-bibl/monogr
    let $tei-monogr :=
        if ($monogr) then
            <monogr>
                {$monogr/(author|editor),$translators-monogr}
                {$monogr/title[not(@type='short')]}
                {if ($tei-analytic) then () else ($all-idnos[.!=''],$refs)}
                {element imprint {$monogr/imprint/*[not(name()='biblScope') and not(name()='note')]}}
                {$biblScopes-monogr-new}
            </monogr>
            else()
    let $series := $zotero-bibl/series
    let $tei-series :=
        if ($series) then
            <series>
                {$series/(author|editor)}
                {$series/title[not(@type='short')]}
                {$biblScopes-series-new}
            </series>
            else()
    
    
        
    let $titles-all := $zotero-bibl//title[not(@type='short')]
    
    let $tei-record :=
    
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    {$titles-all}
                    <sponsor>Biblia Arabica</sponsor>
                    <funder>Deutsche Forschungsgemeinschaft</funder>
                    <principal>Ronny Vollandt</principal>
                    <editor role="general" ref="http://biblia-arabica.com/documentation/editors.xml#rvollandt">Ronny Vollandt</editor>
                    <editor role="general" ref="http://biblia-arabica.com/documentation/editors.xml#ngibson">Nathan P. Gibson</editor>
                    <respStmt>
                        <resp>Bibliography curation by</resp>
                        <name>Biblia Arabica research team</name>
                    </respStmt>
                    <respStmt>
                        <resp>TEI encoding by</resp>
                        <name ref="http://biblia-arabica.com/documentation/editors.xml#ngibson">Nathan P. Gibson</name>
                    </respStmt>
                </titleStmt>
                <publicationStmt>
                    <authority>Biblia Arabica</authority>
                    <idno type="URI">http://biblia-arabica.com/bibl/{$bibl-id}/tei</idno>
                    <availability>
                        <licence target="http://creativecommons.org/licenses/by/3.0/">
                            <p>Distributed under a Creative Commons Attribution 3.0 Unported License.</p>
                        </licence>
                    </availability>
                    <date>{current-date()}</date>
                </publicationStmt>
                <sourceDesc>
                    <p>Born digital.</p>
                </sourceDesc>
            </fileDesc>
            <revisionDesc>
                <change who="http://biblia-arabica.com/documentation/editors.xml#ngibson" when="{current-date()}">CREATED: bibl</change>
            </revisionDesc>
        </teiHeader>
        <text>
            <body>
                <biblStruct>
                    {$tei-analytic}
                    {$tei-monogr}
                    {$tei-series}
                    {$abstract}
                    {$subject-uri[.!='']}
                    {$tags}
                    {$notes}
                </biblStruct>
            </body>
        </text>
    </TEI>
    
    let $collection-uri := "/db/apps/ba-data/data/bibl/tei/"
    let $resource-name := concat($bibl-id,'.xml')
    let $matching-bibl := $bibls[*[1]/idno=$ba-idno]
(:    let $matching-bibl := $bibls[*[1]/idno=$zotero-idno]:)
    
    return 
        if ($matching-bibl) then
            (concat('The bibl with URI ', $ba-idno/text(),' was not created because one with the same URI already exists in the database.'),
            if ($subject-uri) then update insert $subject-uri into $matching-bibl else ())
        else 
            xmldb:store($collection-uri, $resource-name, $tei-record)