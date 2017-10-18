require 'csv'
require 'pry'
require 'nokogiri'
require 'active_support/inflector'

class XmlBuilder
  attr_accessor :fields_hash, :formatted_fields

  def create(file)
    get_fields(file)
    build_fields
    xml_string = build_xml(:Inspecao__c) do |xml|
      @formatted_fields.each do |key, value|
        xml.fields do
          value.each do |key, value|
            xml.send(key, value)
          end
        end
      end
    end

    file = File.open('object.xml', 'wb')
    file.write xml_string
    file.close
  end

  def get_fields(file)
    fields_hash = {}

    CSV.foreach(file, headers: true, col_sep: ';') do |row|
      fields_hash = row.to_hash
    end

    @fields_hash = fields_hash
  end

  def build_fields
    formatted_fields = {}

    @fields_hash.each do |key, value|
      formatted_fields[key] = {}
      formatted_fields[key][:fullName] = format_salesforce_api_name(key)
      formatted_fields[key][:externalId] = false
      formatted_fields[key][:label] = key
      if value == 'number'
        formatted_fields[key][:precision] = 5
      elsif value == 'text'
        formatted_fields[key][:length] = 255
      end
      formatted_fields[key][:required] = false
      formatted_fields[key][:trackHistory] = false
      formatted_fields[key][:trackTrending] = false
      if value == 'text'
        formatted_fields[key][:type] = 'Text'
      elsif value == 'date'
        formatted_fields[key][:type] = 'Date'
      elsif value == 'number'
        formatted_fields[key][:type] = 'Number'
      elsif value == 'date_hour'
        formatted_fields[key][:type] = 'DateTime'
      elsif value == 'boolean'
        formatted_fields[key][:type] = 'Checkbox'
      end
      formatted_fields[key][:unique] = false
    end

    @formatted_fields = formatted_fields
  end

  def build_xml(root, options={}, &block)
    Nokogiri::XML::Builder.new { |xml|
      xml.send(root, { xmlns: 'http://soap.sforce.com/2006/04/metadata' }.merge(options), &block)
    }.to_xml(encoding: 'UTF-8')
  end

  def format_salesforce_api_name(string)
    string.gsub("/", "").split(" ").map { |el| el.parameterize.capitalize }.join("") + "__c"
  end
end