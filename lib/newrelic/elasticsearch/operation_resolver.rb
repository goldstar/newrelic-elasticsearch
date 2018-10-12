require "cgi"

class NewRelic::ElasticsearchOperationResolver
  module Inflector
    refine String do
      def legalize
        # elasticsearch indexes cannot have underscores in the name
        # and datastore metrics cannot have dashes

        self.split('-').map { |w| w[0].upcase + w[1..-1] }.join.gsub(/(Production)|(Staging)/,'')
      end
    end
  end

  ELASTICSEARCH_OPERATION_NAMES =
    {
      [ "PUT", nil ] => :ambiguous_put_resolver,
      [ "POST", nil ] => :ambiguous_post_resolver,
      [ "HEAD", nil ] => :ambiguous_head_resolver,
      [ "GET", nil ] => :ambiguous_get_resolver,
      [ "DELETE", nil ] => :ambiguous_delete_resolver,
      [ "HEAD", "_alias" ] => "AliasesExist",
      [ "PUT", "_alias" ] => "IndexPutAlias",
      [ "DELETE", "_alias" ] => "IndexDeleteAliases",
      [ "GET", "_alias" ] => "GetAliases",
      [ "GET", "_aliases" ] => "GetIndicesAliases",
      [ "POST", "_aliases" ] => "IndicesAliases",
      [ "GET", "_analyze" ] => "Analyze",
      [ "POST", "_analyze" ] => "Analyze",
      [ "POST", "_bulk" ] => "Bulk",
      [ "PUT", "_bulk" ] => "Bulk",
      [ "GET", "_cache" ] => "ClearIndicesCache",
      [ "POST", "_cache" ] => "ClearIndicesCache",
      [ "GET", "_cat" ] => :ambiguous_cat_resolver,
      [ "POST", "_close" ] => "CloseIndex",
      [ "POST", "_cluster" ] => "ClusterReroute",
      [ "GET", "_cluster" ] => :ambiguous_cluster_resolver,
      [ "PUT", "_cluster" ] => "ClusterUpdateSettings",
      [ "GET", "_count" ] => "Count",
      [ "POST", "_count" ] => "Count",
      [ "POST", "_create" ] => "CreateDocument",
      [ "PUT", "_create" ] => "CreateDocument",
      [ "GET", "_explain" ] => "Explain",
      [ "POST", "_explain" ] => "Explain",
      [ "GET", "_flush" ] => "Flush",
      [ "POST", "_flush" ] => "Flush",
      [ "POST", "_gateway" ] => "GatewaySnapshot",
      [ "GET", "_id" ] => "SearchScroll",
      [ "DELETE", "_id" ] => "ClearScroll",
      [ "POST", "_id" ] => "SearchScroll",
      [ "POST", "_mapping" ] => "PutMapping",
      [ "PUT", "_mapping" ] => "PutMapping",
      [ "GET", "_mapping" ] => "GetMapping",
      [ "DELETE", "_mapping" ] => "DeleteMapping",
      [ "POST", "_mget" ] => "MultiGet",
      [ "GET", "_mget" ] => "MultiGet",
      [ "GET", "_mlt" ] => "MoreLikeThis",
      [ "POST", "_mlt" ] => "MoreLikeThis",
      [ "POST", "_mpercolate" ] => "MultiPercolate",
      [ "POST", "_msearch" ] => "MultiSearch",
      [ "GET", "_msearch" ] => "MultiSearch",
      [ "POST", "_mtermvectors" ] => "MultiTermVectors",
      [ "GET", "_mtermvectors" ] => "MultiTermVectors",
      [ "GET", "_nodes" ] => :ambiguous_nodes_resolver,
      [ "POST", "_open" ] => "OpenIndex",
      [ "POST", "_optimize" ] => "Optimize",
      [ "GET", "_optimize" ] => "Optimize",
      [ "GET", "_percolate" ] => :ambiguous_percolate_resolver,
      [ "POST", "_percolate" ] => :ambiguous_percolate_resolver,
      [ "DELETE", "_query" ] => "DeleteByQuery",
      [ "GET", "_refresh" ] => "Refresh",
      [ "POST", "_refresh" ] => "Refresh",
      [ "POST", "_reindex" ] => "Reindex",
      [ "POST", "_restart" ] => "NodesRestart",
      [ "GET", "_search" ] => :ambiguous_search_resolver,
      [ "POST", "_search" ] => :ambiguous_search_resolver,
      [ "DELETE", "_search" ] => "ClearScroll",
      [ "GET", "_segments" ] => "IndicesSegments",
      [ "PUT", "_settings" ] => "UpdateSettings",
      [ "GET", "_settings" ] => "GetSettings",
      [ "GET", "_search_shards" ] => "ClusterSearchShards",
      [ "POST", "_search__shards" ] => "ClusterSearchShards",
      [ "POST", "_shutdown" ] => "NodesShutdown",
      [ "HEAD", "_source" ] => "HeadSource",
      [ "GET", "_source" ] => "GetSource",
      [ "GET", "_stats" ] => :ambiguous_stats_resolver,
      [ "GET", "_status" ] => "IndicesStatus",
      [ "GET", "_suggest" ] => "Suggest",
      [ "POST", "_suggest" ] => "Suggest",
      [ "POST", "_template" ] => "PutIndexTemplate",
      [ "PUT", "_template" ] => "PutIndexTemplate",
      [ "DELETE", "_template" ] => "DeleteIndexTemplate",
      [ "GET", "_template" ] => "GetIndexTemplate",
      [ "HEAD", "_template" ] => "HeadIndexTemplate",
      [ "GET", "_termvector" ] => "TermVector",
      [ "POST", "_termvector" ] => "TermVector",
      [ "GET", "_threads" ] => "NodesHotThreads",
      [ "POST", "_update" ] => "Update",
      [ "GET", "_validate" ] => "ValidateQuery",
      [ "POST", "_validate" ] => "ValidateQuery",
      [ "GET", "_warmer" ] => "GetWarmer",
      [ "PUT", "_warmer" ] => "PutWarmer",
      [ "DELETE", "_warmer" ] => "DeleteWarmer"
  }

  AMBIGUOUS_API_OPS = {
    0 => 'Server',
    1 => 'Index',
    2 => 'Type',
    3 => 'Document'
  }

  AMBIGOUS_CAT_OPS = {
    "indices" => "Indices",
    "master" => "Cluster",
    "nodes" => "Nodes",
    "shards" => "Shards",
    "aliases" => "Aliases"
  }

  attr_accessor :http_method, :path

  using Inflector

  def initialize(http_method, path)
    @http_method = http_method
    @path = path
  end

  def operation_name
    resolved = ELASTICSEARCH_OPERATION_NAMES[[http_method, api_name]]
    case resolved
    when Symbol
      send(resolved)
    else
      resolved
    end
  end

  def path_components
    @path_components ||= CGI::unescape(path).split('/').reject { |s| s.empty? }
  end

  def operands
    if api_name.nil?
      []
    else
      path_components[op_index + 1 .. -1]
    end
  end

  def api_name
    return nil if op_index.nil?
    path_components[op_index]
  end

  def scope
    if api_name.nil?
      path_components
    else
      path_components[0 .. (op_index - 1)]
    end
  end

  def scope_path
    scope.join("_")
  end

  def index
    index = scope[0]
    return nil unless index
    index.legalize unless index.start_with?('_')
  end

  def type
    scope[1].legalize
  end

  def id
    scope[2]
  end

  def op_index
    @op_index ||= path_components.index { |c| c.start_with?('_') }
  end

  def ambiguous_put_resolver
    AMBIGUOUS_API_OPS[scope.count] + "Create"
  end

  alias_method :ambiguous_post_resolver, :ambiguous_put_resolver

  def ambiguous_head_resolver
    AMBIGUOUS_API_OPS[scope.count] + "Exists"
  end

  def ambiguous_get_resolver
    AMBIGUOUS_API_OPS[scope.count] + "Get"
  end

  def ambiguous_delete_resolver
    AMBIGUOUS_API_OPS[scope.count] + "Delete"
  end

  def ambiguous_cat_resolver
    "Cat" + AMBIGOUS_CAT_OPS[operands.first]
  end

  def ambiguous_nodes_resolver
    "Node" + operands[1..-1].map{ |s| s.legalize }.join
  end

  def ambiguous_percolate_resolver
    "Percolate" + operands.first.to_s
  end

  def ambiguous_search_resolver
    "Search" + operands.first.to_s
  end

  def ambiguous_stats_resolver
    "Indicies" + operands.map { |s| s.legalize }.join
  end

  def ambiguous_cluster_resolver
    case operands.join('/')
    when /pending_tasks/ then "ClusterPendingTasks"
    when /nodes\/_restart/ then "NodesRestart"
    when /nodes\/(.*?)\/_restart/ then "NodesRestart"
    when /nodes\/(>*?)\/_shutdown/ then "NodesShutdown"
    end
  end
end
