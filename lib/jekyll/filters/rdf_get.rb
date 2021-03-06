##
# MIT License
#
# Copyright (c) 2016 Elias Saalmann, Christian Frommert, Simon Jakobi,
# Arne Jonas Präger, Maxi Bornmann, Georg Hackel, Eric Füg
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

module Jekyll

  ##
  # Internal module to hold the medthod #rdf_get
  #
  module RdfGet
    def rdf_get(request_uri)
      request_uri = rdf_resolve_prefix_temp(request_uri)
      ask_exist = "ASK WHERE {{<#{request_uri}> ?p ?o}UNION{?s <#{request_uri}> ?o}UNION{?s ?p <#{request_uri}>}} "
      return unless (Jekyll::RdfHelper::sparql.query(ask_exist).true?)
      Jekyll::Drops::RdfResource.new(RDF::URI(request_uri), Jekyll::RdfHelper::sparql, Jekyll::RdfHelper::site, Jekyll::RdfHelper::page)
    end

    #this is only temporary, we will use Jekyll::RdfPrefixResolver -> rdf_resolve_prefix when we fixed it to 3.0.0
    private
    def rdf_resolve_prefix_temp(predicate)
      if(predicate[0] == "<" && predicate[-1] == ">")
        return predicate[1..-2]
      end
      arr=predicate.split(":",2)  #bad regex, would also devide 'http://example....' into 'http' and '//example....',even though it is already a complete URI; if 'PREFIX http: <http://...> is defined, 'http' in 'http://example....' could be mistaken for a prefix
      if((arr[1].include? (":")) || (arr[1][0..1].eql?("//")))
        raise UnMarkedUri.new(predicate, Jekyll::RdfHelper::page.data['template'])
      end
      if(!Jekyll::RdfHelper::page.data["rdf_prefixes"].nil?)
        if(!Jekyll::RdfHelper::page.data["rdf_prefix_map"][arr[0]].nil?)
          return arr[1].prepend(Jekyll::RdfHelper::page.data["rdf_prefix_map"][arr[0]])
        else
          raise NoPrefixMapped.new(predicate, Jekyll::RdfHelper::page.data['template'], arr[0])
        end
      else
        raise NoPrefixesDefined.new(predicate, Jekyll::RdfHelper::page.data['template'])
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::RdfGet)