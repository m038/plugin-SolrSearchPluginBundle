{{* Put this in your template root folder. *}}
    <aside>

        {{* The types represent the indexable types and their subtypes (e.g. the article types for articles) *}}
        {{ $types = $smarty.get.type }}
        {{ if !$types }}
            {{ $types = ['news', 'link', 'comment', 'user'] }}
        {{ /if }}
        {{ if in_array('x', $types) }}
            {{ $types = ['x', 'news', 'link', 'comment', 'user'] }}
        {{ /if }}

        <h4>Refine Search</h4>
        <form id="searchFilters" action="/search" method="get">
            <input type="hidden" name="q" value="{{ $smarty.get.q|escape }}" />

            <ul class="search-filter">
                {{ $options = ['x' => 'All', 'news' => 'News', 'link' => 'Links', 'comment' => 'Comments', 'user' => 'Users' ] }}
                {{ foreach $options as $val => $title }}
                    <li class="li_{{ $val }}" id="li_{{ $val }}">
                    <input{{ if in_array($val, $types) }} checked{{ /if }} class="{{ $val }}_check type-check" name="type[]" value="{{ $val|escape }}" type="checkbox" id="filter_{{ $val }}" onchange="this.form.submit();">
                    <label for="filter_{{ $val }}" class="ui-button ui-widget ui-state-default ui-corner-all ui-button-icon-only" role="button" aria-disabled="false" title="{{ $val }}" aria-pressed="false">
                    <span class="ui-button-text">{{ $title }}</span>
                       </label>
                    </li>
                {{ /foreach }}
            </ul>

            <script type="text/javascript">
                $(function() {
                    var toggleCheckbox = $('.type-check').first();
                    $('.type-check').not(':first').change(function(e) {
                        if (!$(this).prop('checked')) {
                            $(toggleCheckbox).prop('checked', false).change();
                        }
                        $(this).closest('form').submit();
                    });
                });
            </script>

            <ul class="search-filter">
                
                {{ $active = $smarty.get.published }}
                {{* These values are predefined *}}
                {{ $options = ['*' => 'All', '24h' => 'Last 24 hour', '7d' => 'Last 7 days', '14d' => 'Last 14 days', '1m' => 'Last month', '1y' => 'Last year'] }}
                
                {{* Uncomment the following line to use custom formats. For more info see http://lucene.apache.org/solr/4_10_3/solr-core/org/apache/solr/util/DateMathParser.html *}}
                {{* $options = ['*' => 'All', '[NOW-1HOUR/HOUR TO *]' => 'Last hour', '[NOW-3DAYS/DAY TO *]' => 'Last 3days', '[NOW-2MONTHS/DAY TO *]' => 'Last 2 months'] *}}
                
                {{ foreach $options as $val => $title }}
                    {{ $htmlTitle = $title|lower|replace:' ':'' }}
                    <li class="li_pub_{{ $htmlTitle }}" id="li_pub_{{ $htmlTitle }}">
                        <input{{ if $active == $val }} checked{{ /if }} class="pub_{{ $htmlTitle }}_check" name="published" value="{{ $val }}" type="radio" id="filter_pub_{{ $htmlTitle }}" onchange="this.form.submit();">
                        <label for="filter_pub_{{ $htmlTitle }}" class="ui-button ui-widget ui-state-default ui-corner-all ui-button-icon-only" role="button" aria-disabled="false" aria-pressed="false">
                            <span class="ui-button-text">{{ $title }}</span>
                        </label>
                    </li>
                {{ /foreach }}

                {{ if !$smarty.get.published && $smarty.get.from }}
                    <input type="hidden" name="from" value="{{ $smarty.get.from|escape }}" />
                {{ /if }}
                {{ if !$smarty.get.published && $smarty.get.to }}
                    <input type="hidden" name="to" value="{{ $smarty.get.to|escape }}" />
                {{ /if }}
            </ul>

        </form>
    </aside>

    <div class="main-content">
        <div class="search_results_wrap">
            <p>Suchresultate für</p>
            <fieldset class="search">
            {{ form_search_solr class="hidden-phone" }}
                {{ foreach $smarty.get.type as $type }}
                    <input type="hidden" name="type[]" value="{{ $type|escape }}">
                {{ /foreach }}
                {{ $qVal = $smarty.get.q }}
                {{ if $qVal === "-title:Archive" }}
                    {{ $qVal = "" }}
                {{ /if }}
              {{ form_text name="q" value=$smarty.get.q placeholder="{{ $smarty.get.q|default:''|escape }}" }}
              {{ form_submit name="" value="Go" }}
            {{ /form_search_solr }}
            </fieldset>
        </div>

        {{ $fqtype = $types }}

        {{ $listStart = $smarty.get.start|default:0 }}
        {{ $listRows = 3 }}

        {{ $fq = {{ build_solr_fq dateformat="d.m.Y" published=$smarty.get.published type=$fqtype from=$smarty.get.from to=$smarty.get.to }} }}

        {{ list_search_results_solr qf="title user message" q=$smarty.get.q fq=$fq rows=$listRows start=$listStart }}

            {{ if $gimme->current_list->at_beginning }}

                <p>{{ $gimme->current_list->count }} result(s) found.</p>

                <ul class="search-results-list">

            {{ /if }}
         
            {{ if $gimme->solr_result->getType() == 'article' }}
                <h6><a href="">{{ $gimme->solr_result->getObject()->name }}</a></h6>
            {{ elseif $gimme->solr_result->getType() == 'user' }}
                <h6>{{ $gimme->solr_result->getObject()->name }}</h6>
            {{ elseif $gimme->solr_result->getType() == 'comment' }}
                <h6>{{ $gimme->solr_result->getObject()->content }}</h6>
            {{ /if }}

            {{ if $gimme->current_list->at_end }}   
                
                </ul>                  

                {{ $getTypes="" }}       
                {{ foreach $types as $type name="tipovi" }}
                    {{ if $smarty.foreach.tipovi.first }}
                    {{ $types = $smarty.get.type }}        
                    {{ $getTypes="&type[]={{ $type }}" }}
                    {{ else }}
                    {{ $getTypes="{{ $getTypes }}&type[]={{ $type }}" }}
                    {{ /if }}
                {{ /foreach }}
                {{ $getPublished=$smarty.get.published }} 
                {{ $getFrom=$smarty.get.from }}
                {{ $getTo=$smarty.get.to }}
                {{ if $getTo || $getFrom }}{{ $getPublished="" }}{{ /if }}    
                {{ $curpage=floor($listStart/$listRows) }}
                {{ $nextstart=$listStart+$listRows }}
                {{ $prevstart=($listStart-$listRows) }}
                
                <ul class="paging center top-line">
                  
                  {{ if $gimme->current_list->has_previous_elements }}
                  <li><a class="button white prev" href="/search?q={{ $smarty.get.q|escape }}{{ $getTypes }}{{ if $getPublished }}&published={{ $getPublished }}{{ /if }}{{ if $getTo }}&to={{ $getTo }}{{ /if }}{{ if $getFrom }}&from={{ $getFrom }}{{ /if }}&start={{ $prevstart }}">prev</a></li>
                  {{ /if }}
                  <li class="caption">{{ $curpage+1 }} of {{ ceil($gimme->current_list->count/$listRows) }}</li>
                  {{ if $gimme->current_list->has_next_elements }}
                  <li><a class="button white next" href="/search?q={{ $smarty.get.q|escape }}{{ $getTypes }}{{ if $getPublished }}&published={{ $getPublished }}{{ /if }}{{ if $getTo }}&to={{ $getTo }}{{ /if }}{{ if $getFrom }}&from={{ $getFrom }}{{ /if }}&start={{ $nextstart }}">next</a></li>
                  {{ /if }}
                </ul>          

            {{ /if }} 

        {{ /list_search_results_solr }}

        {{ if $gimme->prev_list_empty }}
            <h3>No results </h3>
        {{ /if }}

</div>
