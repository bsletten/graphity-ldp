<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright (C) 2012 Martynas Jusevičius <martynas@graphity.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY java "http://xml.apache.org/xalan/java/">
    <!ENTITY g "http://graphity.org/ontology/">
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY owl "http://www.w3.org/2002/07/owl#">
    <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY sparql "http://www.w3.org/2005/sparql-results#">
    <!ENTITY geo "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY dbpedia-owl "http://dbpedia.org/ontology/">
    <!ENTITY dc "http://purl.org/dc/elements/1.1/">
    <!ENTITY dct "http://purl.org/dc/terms/">
    <!ENTITY foaf "http://xmlns.com/foaf/0.1/">
    <!ENTITY sioc "http://rdfs.org/sioc/ns#">
    <!ENTITY sp "http://spinrdf.org/sp#">
    <!ENTITY sd "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY list "http://jena.hpl.hp.com/ARQ/list#">
]>
<xsl:stylesheet version="2.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:g="&g;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:owl="&owl;"
xmlns:sparql="&sparql;"
xmlns:geo="&geo;"
xmlns:dbpedia-owl="&dbpedia-owl;"
xmlns:dc="&dc;"
xmlns:dct="&dct;"
xmlns:foaf="&foaf;"
xmlns:sioc="&sioc;"
xmlns:sp="&sp;"
xmlns:sd="&sd;"
xmlns:list="&list;"
exclude-result-prefixes="xsl xhtml xs g rdf rdfs owl sparql geo dbpedia-owl dc dct foaf sioc sp sd list">

    <xsl:import href="imports/default.xsl"/>
    <xsl:import href="imports/foaf.xsl"/>
    <xsl:import href="imports/doap.xsl"/>
    <xsl:import href="imports/void.xsl"/>
    <xsl:import href="imports/sd.xsl"/>
    <xsl:import href="imports/dbpedia-owl.xsl"/>
    <xsl:import href="imports/facebook.xsl"/>

    <xsl:import href="functions.xsl"/>

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" media-type="application/xhtml+xml"/>
    
    <xsl:preserve-space elements="pre"/>

    <xsl:param name="base-uri" as="xs:anyURI"/>
    <xsl:param name="absolute-path" as="xs:anyURI"/>
    <xsl:param name="http-headers" as="xs:string"/>

    <xsl:param name="uri" select="$absolute-path" as="xs:anyURI"/>
    <xsl:param name="endpoint-uri" select="$resource/g:service/@rdf:resource" as="xs:anyURI?"/> <!-- select="xs:anyURI(concat($base-uri, 'sparql'))"  -->
    <xsl:param name="mode" select="if ($resource/g:mode/@rdf:resource) then $resource/g:mode/@rdf:resource else xs:anyURI('&g;ListMode')" as="xs:anyURI"/>
    <xsl:param name="action" select="false()"/>
    <xsl:param name="lang" select="'en'" as="xs:string"/>

    <xsl:param name="query-model" select="document($query-uri)" as="document-node()?"/>
    <xsl:param name="offset" select="$select-query/sp:offset" as="xs:integer?"/>
    <xsl:param name="limit" select="$select-query/sp:limit" as="xs:integer?"/>
    <xsl:param name="order-by" select="key('resources', $orderBy/sp:expression/@rdf:resource, $query-model)/sp:varName" as="xs:string?"/>
    <xsl:param name="desc" select="$orderBy[1]/rdf:type/@rdf:resource = '&sp;Desc'" as="xs:boolean"/>

    <xsl:param name="query-uri" select="$resource/g:query/@rdf:resource" as="xs:anyURI?"/>
    <xsl:param name="query" select="$select-query/sp:text" as="xs:string?"/>
    <xsl:param name="where" select="list:member(key('resources', $select-query/sp:where/@rdf:nodeID, $query-model), $query-model)"/>
    <xsl:param name="orderBy" select="if ($select-query/sp:orderBy) then list:member(key('resources', $select-query/sp:orderBy/@rdf:nodeID, $query-model), $query-model) else ()"/>

    <xsl:variable name="resource" select="key('resources', $uri, $ont-model)" as="element()?"/>
    <xsl:variable name="ont-uri" select="resolve-uri('ontology/', $base-uri)" as="xs:anyURI"/>
    <xsl:variable name="ont-model" select="document($ont-uri)" as="document-node()"/>
    <xsl:variable name="graphity-ont-model" select="document('&g;')" as="document-node()"/>
    <xsl:variable name="select-query" select="if ($query-uri) then key('resources', $query-uri, $query-model) else ()" as="element()?"/>
	
    <xsl:key name="resources" match="*[*][@rdf:about] | *[*][@rdf:nodeID]" use="@rdf:about | @rdf:nodeID"/>
    <xsl:key name="predicates" match="*[@rdf:about]/* | *[@rdf:nodeID]/*" use="concat(namespace-uri(.), local-name(.))"/>
    <xsl:key name="resources-by-host" match="*[@rdf:about]" use="sioc:has_host/@rdf:resource"/>
 
    <rdf:Description rdf:nodeID="previous">
	<rdfs:label xml:lang="en">Previous</rdfs:label>
    </rdf:Description>

    <rdf:Description rdf:nodeID="next">
	<rdfs:label xml:lang="en">Next</rdfs:label>
    </rdf:Description>

    <xsl:template match="rdf:RDF">
	<div class="span8">
	    <div class="nav row-fluid">
		<ul class="nav nav-tabs pull-right">
		    <li>
			<xsl:if test="$mode = '&g;ListMode'">
			    <xsl:attribute name="class">active</xsl:attribute>
			</xsl:if>
			<xsl:choose>
			    <xsl:when test="$uri != $absolute-path">
				<a href="{$absolute-path}{g:query-string($uri, $endpoint-uri, $offset, $limit, $order-by, $desc, $lang, '&g;ListMode')}">List</a>
			    </xsl:when>
			    <xsl:otherwise>
				<a href="{$absolute-path}{g:query-string($offset, $limit, $order-by, $desc, $lang, '&g;ListMode')}">List</a>
			    </xsl:otherwise>
			</xsl:choose>
		    </li>
		    <li>
			<xsl:if test="$mode = '&g;TableMode'">
			    <xsl:attribute name="class">active</xsl:attribute>
			</xsl:if>
			<xsl:choose>
			    <xsl:when test="$uri != $absolute-path">
				<a href="{$absolute-path}{g:query-string($uri, $endpoint-uri, $offset, $limit, $order-by, $desc, $lang, '&g;TableMode')}">Table</a>
			    </xsl:when>
			    <xsl:otherwise>
				<a href="{$absolute-path}{g:query-string($offset, $limit, $order-by, $desc, $lang, '&g;TableMode')}">Table</a>
			    </xsl:otherwise>
			</xsl:choose>
		    </li>
		</ul>

		<div class="btn-group pull-right">
		    <xsl:if test="$uri != $absolute-path">
			<a href="{$uri}" class="btn">Source</a>
		    </xsl:if>
		    <xsl:if test="$query">
			<a href="{resolve-uri('sparql', $base-uri)}?query={encode-for-uri($query)}{if ($endpoint-uri) then (concat('&amp;endpoint-uri=', encode-for-uri($endpoint-uri))) else ()}" class="btn">SPARQL</a>
		    </xsl:if>
		    <a href="?uri={encode-for-uri($uri)}&amp;accept={encode-for-uri('application/rdf+xml')}" class="btn">RDF/XML</a>
		    <a href="?uri={encode-for-uri($uri)}&amp;accept={encode-for-uri('text/turtle')}" class="btn">Turtle</a>
		</div>
	    </div>

	    <xsl:apply-templates select="." mode="g:PaginationMode"/>

	    <xsl:if test="$mode = '&g;ListMode'">
		<xsl:apply-templates mode="g:ListMode"/>
	    </xsl:if>
	    
	    <xsl:if test="$mode = '&g;TableMode'">
		<!-- <xsl:variable name="predicate-uris" select="distinct-values(*/*/xs:anyURI(concat(namespace-uri(.), local-name(.))))" as="xs:anyURI*"/> -->
		<xsl:variable name="predicates" as="element()*">
		    <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(.), local-name(.))">
			<xsl:sort select="g:label(xs:anyURI(concat(namespace-uri(.), local-name(.))), /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
			<xsl:sequence select="current-group()[1]"/>
		    </xsl:for-each-group>
		</xsl:variable>
	    
		<table class="table table-bordered table-striped">
		    <thead>
			<tr>
			    <th>
				<a href="{$absolute-path}{g:query-string($offset, $limit, (), $desc, $lang, $mode)}">
				    <xsl:value-of select="g:label(xs:anyURI('&rdf;Resource'), /, $lang)"/>
				</a>
			    </th>

			    <xsl:apply-templates select="$predicates" mode="g:TableHeaderMode"/>
			</tr>
		    </thead>
		    <tbody>
			<xsl:apply-templates mode="g:TableMode">
			    <xsl:with-param name="predicates" select="$predicates"/>
			</xsl:apply-templates>
		    </tbody>
		</table>
	    </xsl:if>
	    
	    <xsl:apply-templates select="." mode="g:PaginationMode"/>
	</div>

	<div class="span4">
	    <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(.), local-name(.))">
		<xsl:sort select="g:label(xs:anyURI(concat(namespace-uri(.), local-name(.))), /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
		<xsl:apply-templates select="current-group()[1]" mode="g:SidebarNavMode"/>
	    </xsl:for-each-group>
	</div>
    </xsl:template>

    <!-- matches if the RDF/XML document includes resource description where @rdf:about = $uri -->
    <xsl:template match="rdf:RDF[key('resources', $uri) or count(*) = 1]">
	<div class="span8">
	    <!-- the main resource, which matches the request URI -->
	    <xsl:choose>
		<xsl:when test="key('resources', $uri)">
		    <xsl:apply-templates select="key('resources', $uri)"/>
		</xsl:when>
		<xsl:otherwise>
		    <xsl:apply-templates/>
		</xsl:otherwise>
	    </xsl:choose>
	    
	    <!-- secondary resources (except the main one and blank nodes) that came with the response -->
	    <!-- <xsl:apply-templates select="*[@rdf:about] except key('resources', $uri)" mode="g:ListMode"/> -->
	</div>

	<div class="span4">
	    <xsl:choose>
		<xsl:when test="key('resources', $uri)">
		    <xsl:for-each-group select="key('resources', $uri)/*" group-by="concat(namespace-uri(.), local-name(.))">
			<xsl:sort select="g:label(xs:anyURI(concat(namespace-uri(.), local-name(.))), /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
			<xsl:apply-templates select="current-group()[1]" mode="g:SidebarNavMode"/>
		    </xsl:for-each-group>
		</xsl:when>
		<xsl:otherwise>
		    <xsl:for-each-group select="*/*" group-by="concat(namespace-uri(.), local-name(.))">
			<xsl:sort select="g:label(xs:anyURI(concat(namespace-uri(.), local-name(.))), /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
			<xsl:apply-templates select="current-group()[1]" mode="g:SidebarNavMode"/>
		    </xsl:for-each-group>
		</xsl:otherwise>
	    </xsl:choose>
	</div>
    </xsl:template>

    <!-- subject -->
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]">
	<div>
	    <xsl:apply-templates select="." mode="g:HeaderMode"/>
	    
	    <xsl:apply-templates select="." mode="g:PropertyListMode"/>
	</div>
    </xsl:template>    

    <xsl:template match="rdf:type/@rdf:resource">
	<span title="{.}" class="btn">
	    <xsl:apply-imports/>
	</span>
    </xsl:template>

    <!-- HEADER MODE -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="g:HeaderMode">
	<!-- <xsl:if test="@rdf:about or foaf:depiction/@rdf:resource or foaf:logo/@rdf:resource or rdf:type/@rdf:resource or rdfs:comment[lang($lang) or not(@xml:lang)] or dc:description[lang($lang) or not(@xml:lang)] or dct:description[lang($lang) or not(@xml:lang)] or dbpedia-owl:abstract[lang($lang) or not(@xml:lang)]"> -->
	<div class="well well-large">
	    <xsl:if test="self::foaf:Image or rdf:type/@rdf:resource = '&foaf;Image' or foaf:img/@rdf:resource or foaf:depiction/@rdf:resource or foaf:logo/@rdf:resource">
		<p style="margin: auto;">
		    <xsl:choose>
			<xsl:when test="self::foaf:Image or rdf:type/@rdf:resource = '&foaf;Image'">
			    <xsl:apply-templates select="@rdf:about"/>
			</xsl:when>
			<xsl:when test="foaf:img/@rdf:resource">
			    <xsl:apply-templates select="foaf:img[1]/@rdf:resource"/>
			</xsl:when>
			<xsl:when test="foaf:depiction/@rdf:resource">
			    <xsl:apply-templates select="foaf:depiction[1]/@rdf:resource"/>
			</xsl:when>
			<xsl:when test="foaf:logo/@rdf:resource">
			    <xsl:apply-templates select="foaf:logo[1]/@rdf:resource"/>
			</xsl:when>
		    </xsl:choose>
		</p>
	    </xsl:if>

	    <xsl:if test="@rdf:about">
		<div class="btn-group pull-right">
		    <xsl:choose>
			<xsl:when test="@rdf:about != $absolute-path">
			    <a href="{@rdf:about}" class="btn">Source</a>
			    <a href="?uri={encode-for-uri(@rdf:about)}&amp;accept={encode-for-uri('application/rdf+xml')}" class="btn">RDF/XML</a>
			    <a href="?uri={encode-for-uri(@rdf:about)}&amp;accept={encode-for-uri('text/turtle')}" class="btn">Turtle</a>
			</xsl:when>
			<xsl:otherwise>
			    <a href="{@rdf:about}?accept={encode-for-uri('application/rdf+xml')}" class="btn">RDF/XML</a>
			    <a href="{@rdf:about}?accept={encode-for-uri('text/turtle')}" class="btn">Turtle</a>
			</xsl:otherwise>
		    </xsl:choose>
		</div>
	    </xsl:if>

	    <xsl:apply-templates select="@rdf:about | @rdf:nodeID" mode="g:HeaderMode"/>

	    <xsl:if test="rdfs:comment[lang($lang) or not(@xml:lang)] or dc:description[lang($lang) or not(@xml:lang)] or dct:description[lang($lang) or not(@xml:lang)] or dbpedia-owl:abstract[lang($lang) or not(@xml:lang)] or sioc:content[lang($lang) or not(@xml:lang)]">
		<p>
		    <xsl:choose>
			<xsl:when test="rdfs:comment[lang($lang) or not(@xml:lang)]">
			    <xsl:value-of select="rdfs:comment[lang($lang) or not(@xml:lang)][1]"/>
			</xsl:when>
			<xsl:when test="dc:description[lang($lang) or not(@xml:lang)]">
			    <xsl:value-of select="dc:description[lang($lang) or not(@xml:lang)][1]"/>
			</xsl:when>
			<xsl:when test="dct:description[lang($lang) or not(@xml:lang)]">
			    <xsl:value-of select="dct:description[lang($lang) or not(@xml:lang)][1]"/>
			</xsl:when>
			<xsl:when test="dbpedia-owl:abstract[lang($lang) or not(@xml:lang)][1]">
			    <xsl:value-of select="dbpedia-owl:abstract[lang($lang) or not(@xml:lang)][1]"/>
			</xsl:when>
			<xsl:when test="sioc:content[lang($lang) or not(@xml:lang)]">
			    <xsl:value-of select="substring(sioc:content[lang($lang) or not(@xml:lang)][1], 1, 300)"/>
			</xsl:when>
		    </xsl:choose>
		</p>
	    </xsl:if>

	    <xsl:if test="rdf:type/@rdf:resource">
		<ul class="inline">
		    <xsl:apply-templates select="rdf:type/@rdf:resource" mode="g:HeaderMode">
			<xsl:sort select="g:label(., /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
		    </xsl:apply-templates>
		</ul>
	    </xsl:if>
	</div>
    </xsl:template>

    <xsl:template match="@rdf:about" mode="g:HeaderMode">
	<h1 class="page-header">
	    <xsl:apply-templates select="."/>
	</h1>
    </xsl:template>

    <xsl:template match="@rdf:nodeID" mode="g:HeaderMode">
	<h2>
	    <xsl:apply-templates select="."/>
	</h2>
    </xsl:template>

    <xsl:template match="rdf:type/@rdf:resource" mode="g:HeaderMode">
	<li>
	    <xsl:apply-templates select="."/>
	</li>
    </xsl:template>

    <!-- PROPERTY LIST MODE -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="g:PropertyListMode">
	<div class="row-fluid">
	    <xsl:variable name="no-domain-properties" select="*[not(rdfs:domain(xs:anyURI(concat(namespace-uri(.), local-name(.)))) = current()/rdf:type/@rdf:resource)]"/>
	    <xsl:variable name="domain-types" select="rdf:type/@rdf:resource[../../*/xs:anyURI(concat(namespace-uri(.), local-name(.))) = g:inDomainOf(.)]"/>

	    <xsl:if test="$no-domain-properties">
		<!-- expand if description contains blank nodes and no type/domain property groups -->
		<div class="span{if (not($domain-types) and $no-domain-properties/@rdf:nodeID) then 12 else 6} well well-small">
		    <dl>
			<xsl:apply-templates select="$no-domain-properties" mode="g:PropertyListMode">
			    <xsl:sort select="g:label(xs:anyURI(concat(namespace-uri(.), local-name(.))), /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
			    <xsl:sort select="if (@rdf:resource) then (g:label(@rdf:resource, /, $lang)) else text()" data-type="text" order="ascending" lang="{$lang}"/> <!-- g:label(@rdf:nodeID, /, $lang) -->
			</xsl:apply-templates>
		    </dl>
		</div>
	    </xsl:if>

	    <xsl:if test="$domain-types">
		<div class="span6">
		    <xsl:apply-templates select="$domain-types" mode="g:TypeMode">
			<xsl:sort select="g:label(., /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
		    </xsl:apply-templates>
		</div>
	    </xsl:if>
	</div>
    </xsl:template>

    <xsl:template match="rdf:type | foaf:img | foaf:depiction | foaf:logo | owl:sameAs | rdfs:label | rdfs:comment | rdfs:seeAlso | dc:title | dct:title | dc:description | dct:description | dct:subject | dbpedia-owl:abstract | sioc:content" mode="g:PropertyListMode" priority="1"/>

    <!-- property -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="g:PropertyListMode">
	<xsl:variable name="this" select="xs:anyURI(concat(namespace-uri(.), local-name(.)))" as="xs:anyURI"/>

	<!-- show <dt> only on the first occurence of property (in a group) -->
	<xsl:if test="not(preceding-sibling::*[concat(namespace-uri(.), local-name(.)) = $this])">
	    <dt>
		<xsl:apply-templates select="."/>
	    </dt>
	</xsl:if>

	<xsl:if test="lang($lang) or not(../*[concat(namespace-uri(.), local-name(.)) = $this][lang($lang)])">
	    <xsl:apply-templates select="node() | @rdf:resource" mode="g:PropertyListMode"/>

	    <xsl:apply-templates select="@rdf:nodeID" mode="g:PropertyListMode"/>
	</xsl:if>
    </xsl:template>

    <xsl:template match="node() | @rdf:resource" mode="g:PropertyListMode">
	<dd>
	    <xsl:apply-templates select="."/>
	</dd>
    </xsl:template>

    <xsl:template match="@rdf:nodeID" mode="g:PropertyListMode">
	<dd>
	    <xsl:apply-templates select="key('resources', .)"/>
	</dd>
    </xsl:template>

    <!-- TYPE MODE -->

    <xsl:template match="rdf:type/@rdf:resource" mode="g:TypeMode">
	<xsl:variable name="in-domain-properties" select="../../*[xs:anyURI(concat(namespace-uri(.), local-name(.))) = g:inDomainOf(current()) or rdfs:domain(xs:anyURI(concat(namespace-uri(.), local-name(.)))) = xs:anyURI(current())][not(@xml:lang) or lang($lang)]"/>

	<div class="well well-small">
	    <h2>
		<xsl:apply-imports/>
	    </h2>
	    <dl class="well-small">
		<xsl:apply-templates select="$in-domain-properties" mode="g:PropertyListMode">
		    <xsl:sort select="g:label(xs:anyURI(concat(namespace-uri(.), local-name(.))), /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
		    <xsl:sort select="if (@rdf:resource) then (g:label(@rdf:resource, /, $lang)) else text()" data-type="text" order="ascending" lang="{$lang}"/> <!-- g:label(@rdf:nodeID, /, $lang) -->
		</xsl:apply-templates>
	    </dl>
	</div>
    </xsl:template>

    <!-- SIDEBAR NAV MODE -->
    
    <xsl:template match="*[@rdf:about]" mode="g:SidebarNavMode">
	<xsl:apply-templates mode="g:SidebarNavMode">
	    <xsl:sort select="g:label(xs:anyURI(concat(namespace-uri(.), local-name(.))), /, $lang)" data-type="text" order="ascending"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="rdfs:seeAlso | owl:sameAs | dc:subject | dct:subject" mode="g:SidebarNavMode" priority="1">
	<xsl:variable name="this" select="xs:anyURI(concat(namespace-uri(.), local-name(.)))" as="xs:anyURI"/>
	
	<div class="well sidebar-nav">
	    <h2 class="nav-header">
		<a href="{$base-uri}{g:query-string($this, $endpoint-uri, (), (), (), (), $lang, ())}" title="{$this}">
		    <xsl:value-of select="g:label($this, /, $lang)"/>
		</a>
	    </h2>
		
	    <!-- TO-DO: fix for a single resource! -->
	    <ul class="nav nav-pills nav-stacked">
		<xsl:for-each-group select="key('predicates', $this)" group-by="@rdf:resource">
		    <xsl:sort select="g:label(@rdf:resource, /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
		    <xsl:apply-templates select="current-group()[1]/@rdf:resource" mode="g:SidebarNavMode"/>
		</xsl:for-each-group>
	    </ul>
	</div>
    </xsl:template>

    <!-- ignore all other properties -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="g:SidebarNavMode"/>

    <xsl:template match="rdfs:seeAlso/@rdf:resource | owl:sameAs/@rdf:resource | dc:subject/@rdf:resource | dct:subject/@rdf:resource" mode="g:SidebarNavMode">
	<li>
	    <xsl:apply-templates select="."/>
	</li>
    </xsl:template>

    <!-- PAGINATION MODE -->

    <xsl:template match="rdf:RDF" mode="g:PaginationMode">
	<xsl:if test="count(*) &gt; 0">
	    <ul class="pager">
		<li class="previous">
		    <xsl:choose>
			<xsl:when test="not($offset &gt;= $limit)">
			    <xsl:attribute name="class">previous disabled</xsl:attribute>
			    <a>
				&#8592; <xsl:value-of select="key('resources', 'previous', document(''))/rdfs:label[lang($lang)]"/>
			    </a>
			</xsl:when>
			<xsl:otherwise>
			    <a href="{$absolute-path}{g:query-string($offset - $limit, $limit, $order-by, $desc, $lang, $mode)}" class="active">
				&#8592; <xsl:value-of select="key('resources', 'previous', document(''))/rdfs:label[lang($lang)]"/>
			    </a>
			</xsl:otherwise>
		    </xsl:choose>
		</li>
		<!--
		<li class="active">
		    <a href="#">1</a>
		</li>
		<li><a href="#">2</a></li>
		<li><a href="#">3</a></li>
		<li><a href="#">4</a></li>
		-->
		<li class="next">
		    <xsl:choose>
			<xsl:when test="count(*) &lt; $limit">
			    <xsl:attribute name="class">next disabled</xsl:attribute>
			    <a>
				<xsl:value-of select="key('resources', 'next', document(''))/rdfs:label[lang($lang)]"/> &#8594;
			    </a>
			</xsl:when>
			<xsl:otherwise>
			    <a href="{$absolute-path}{g:query-string($offset + $limit, $limit, $order-by, $desc, $lang, $mode)}">
				<xsl:value-of select="key('resources', 'next', document(''))/rdfs:label[lang($lang)]"/> &#8594;
			    </a>
			</xsl:otherwise>
		    </xsl:choose>
		</li>
	    </ul>
	</xsl:if>
    </xsl:template>

    <!-- LIST MODE -->

    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="g:ListMode">
	<div class="well">
	    <xsl:if test="self::foaf:Image or rdf:type/@rdf:resource = '&foaf;Image' or foaf:img/@rdf:resource or foaf:depiction/@rdf:resource or foaf:logo/@rdf:resource">
		<div>
		    <xsl:choose>
			<xsl:when test="self::foaf:Image or rdf:type/@rdf:resource = '&foaf;Image'">
			    <xsl:apply-templates select="@rdf:about"/>
			</xsl:when>
			<xsl:when test="foaf:img/@rdf:resource">
			    <xsl:apply-templates select="foaf:img[1]/@rdf:resource"/>
			</xsl:when>
			<xsl:when test="foaf:depiction/@rdf:resource">
			    <xsl:apply-templates select="foaf:depiction[1]/@rdf:resource"/>
			</xsl:when>
			<xsl:when test="foaf:logo/@rdf:resource">
			    <xsl:apply-templates select="foaf:logo[1]/@rdf:resource"/>
			</xsl:when>
		    </xsl:choose>
		</div>
	    </xsl:if>

	    <xsl:if test="(@rdf:about or @rdf:nodeID) and not(self::foaf:Image or rdf:type/@rdf:resource = '&foaf;Image')">
		<h1>
		    <xsl:apply-templates select="@rdf:about | @rdf:nodeID"/>
		</h1>
	    </xsl:if>
	    <xsl:if test="rdf:type/@rdf:resource">
		<ul class="inline">
		    <xsl:for-each select="rdf:type/@rdf:resource">
			<li>
			    <xsl:apply-templates select="."/>
			</li>
		    </xsl:for-each>
		</ul>
	    </xsl:if>
	    <xsl:if test="rdfs:comment[lang($lang) or not(@xml:lang)] or dc:description[lang($lang) or not(@xml:lang)] or dct:description[lang($lang) or not(@xml:lang)] or dbpedia-owl:abstract[lang($lang) or not(@xml:lang)] or sioc:content[lang($lang) or not(@xml:lang)]">
		<p>
		    <xsl:choose>
			<xsl:when test="rdfs:comment[lang($lang) or not(@xml:lang)]">
			    <xsl:value-of select="substring(rdfs:comment[lang($lang) or not(@xml:lang)][1], 1, 300)"/>
			</xsl:when>
			<xsl:when test="dc:description[lang($lang) or not(@xml:lang)]">
			    <xsl:value-of select="substring(dc:description[lang($lang) or not(@xml:lang)][1], 1, 300)"/>
			</xsl:when>
			<xsl:when test="dct:description[lang($lang) or not(@xml:lang)]">
			    <xsl:value-of select="substring(dct:description[lang($lang) or not(@xml:lang)][1], 1, 300)"/>
			</xsl:when>
			<xsl:when test="dbpedia-owl:abstract[lang($lang) or not(@xml:lang)]">
			    <xsl:value-of select="substring(dbpedia-owl:abstract[lang($lang) or not(@xml:lang)][1], 1, 300)"/>
			</xsl:when>
			<xsl:when test="sioc:content[lang($lang) or not(@xml:lang)]">
			    <xsl:value-of select="substring(sioc:content[lang($lang) or not(@xml:lang)][1], 1, 300)"/>
			</xsl:when>
		    </xsl:choose>
		</p>
	    </xsl:if>
	</div>
    </xsl:template>

    <!-- TABLE HEADER MODE -->

    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="g:TableHeaderMode">
	<xsl:variable name="this" select="xs:anyURI(concat(namespace-uri(.), local-name(.)))" as="xs:anyURI"/>

	<th>
	    <a href="{$absolute-path}{g:query-string($offset, $limit, $this, $desc, $lang, $mode)}" title="{$this}">
		<xsl:value-of select="g:label($this, /, $lang)"/>
	    </a>
	</th>
    </xsl:template>

    <!-- TABLE MODE -->
    
    <xsl:template match="*[*][@rdf:about] | *[*][@rdf:nodeID]" mode="g:TableMode">
	<xsl:param name="predicates" as="element()*">
	    <xsl:for-each-group select="../*/*" group-by="concat(namespace-uri(.), local-name(.))">
		<xsl:sort select="g:label(xs:anyURI(concat(namespace-uri(.), local-name(.))), /, $lang)" data-type="text" order="ascending" lang="{$lang}"/>
		<xsl:sequence select="current-group()[1]"/>
	    </xsl:for-each-group>
	</xsl:param>
	
	<tr>
	    <td>
		<xsl:apply-templates select="@rdf:about | @rdf:nodeID"/>
	    </td>

	    <xsl:variable name="subject" select="."/>
	    <xsl:for-each select="$predicates">
		<xsl:variable name="this" select="xs:anyURI(concat(namespace-uri(.), local-name(.)))" as="xs:anyURI"/>
		<xsl:variable name="predicate" select="$subject/*[concat(namespace-uri(.), local-name(.)) = $this]"/>
		<xsl:choose>
		    <xsl:when test="$predicate">
			<xsl:apply-templates select="$predicate" mode="g:TableMode"/>
		    </xsl:when>
		    <xsl:otherwise>
			<td></td>
		    </xsl:otherwise>
		</xsl:choose>
	    </xsl:for-each>
	</tr>
    </xsl:template>

    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*" mode="g:TableMode"/>

    <!-- apply properties that match lang() -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*[lang($lang)]" mode="g:TableMode" priority="1">
	<td>
	    <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID"/>
	</td>
    </xsl:template>
    
    <!-- apply the first one in the group if there's no lang() match -->
    <xsl:template match="*[@rdf:about or @rdf:nodeID]/*[not(../*[concat(namespace-uri(.), local-name(.)) = concat(namespace-uri(current()), local-name(current()))][lang($lang)])][not(preceding-sibling::*[concat(namespace-uri(.), local-name(.)) = concat(namespace-uri(current()), local-name(current()))])]" mode="g:TableMode" priority="1">
	<td>
	    <xsl:apply-templates select="node() | @rdf:resource | @rdf:nodeID"/>
	</td>
    </xsl:template>

</xsl:stylesheet>