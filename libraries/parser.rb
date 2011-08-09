require 'treetop'
require 'chef/solr_query/query_transform'

# mock QueryTransform such that we can access the location of the lucene grammar
class Chef
  class SolrQuery
    class QueryTransform
      def self.base_path
        class_variable_get(:@@base_path)
      end
    end
  end
end

module Lucene

  class Term < Treetop::Runtime::SyntaxNode
    def match( value )
      if self.text_value.end_with?("*")
        value.to_s.start_with?(self.text_value.chomp("*"))
      else
        value.to_s == self.text_value
      end
    end
  end

  class Field < Treetop::Runtime::SyntaxNode
    def match( item )
      name = self.elements[0].text_value
      if item.has_key?(name)
        self.elements[1].match(item[name])
      else
        false
      end
    end
  end
  
  class FiledRange < Treetop::Runtime::SyntaxNode
  end
  
  class InclFieldRange < FieldRange
  end
  
  class ExclFieldRange < FieldRange
  end
  
  class RangeValue < Treetop::Runtime::SyntaxNode
  end
  
  class FieldName < Treetop::Runtime::SyntaxNode
  end

  class Body < Treetop::Runtime::SyntaxNode
    def match( item )
      self.elements[0].match( item )
    end
  end
  
  class Group < Treetop::Runtime::SyntaxNode
    def match( item )
      self.elements[0].match(item)
    end
  end
  
  class BinaryOp < Treetop::Runtime::SyntaxNode
    def match( item )
      self.elements[1].match(
        self.elements[0].match(item),
        self.elements[2].match(item)
      )
    end
  end
  
  class OrOperator < Treetop::Runtime::SyntaxNode
    def match( cond1, cond2 )
      cond1 or cond2
    end
  end
  
  class AndOperator < Treetop::Runtime::SyntaxNode
    def match( cond1, cond2 )
      cond1 and cond2
    end
  end
  
  class FuzzyOp < Treetop::Runtime::SyntaxNode
  end
  
  class BoostOp < Treetop::Runtime::SyntaxNode
  end
  
  class FuzzyParam < Treetop::Runtime::SyntaxNode
  end
  
  class UnaryOp < Treetop::Runtime::SyntaxNode
    def match( item )
      self.elements[0].match(
        self.elements[1].match(item)
      )
    end
  end
  
  class NotOperator < Treetop::Runtime::SyntaxNode
    def match( cond )
      not cond
    end
  end
  
  class RequiredOperator < Treetop::Runtime::SyntaxNode
  end
  
  class ProhibitedOperator < Treetop::Runtime::SyntaxNode
  end
  
  class Phrase < Treetop::Runtime::SyntaxNode
  end
  
end

class Query
  @@grammar = File.join(Chef::SolrQuery::QueryTransform.base_path, "lucene.treetop")
  Treetop.load(@@grammar)
  @@parser = LuceneParser.new

  def self.parse(data)
    tree = @@parser.parse(data)
    if tree.nil?
      raise "Query #{data} is not supported"
    end
    self.clean_tree(tree)
    tree
  end
  
  private

  def self.clean_tree(root_node)
    return if root_node.elements.nil?
    root_node.elements.delete_if do |node|
      node.class.name == "Treetop::Runtime::SyntaxNode"
    end
    root_node.elements.each { |node| self.clean_tree(node) }
  end
end

t = Query.parse("(age:* OR age:78 OR !age:56)")
#puts t
#puts t.elements
puts t.match({"age" => 35})
