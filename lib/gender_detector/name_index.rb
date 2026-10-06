# frozen_string_literal: true

class GenderDetector
  # Maps the names of a dictionary file to their records. The names and records
  # are kept in a few large strings instead of a Hash entry and String per name,
  # which keeps the dictionary at a fraction of the memory: the name at index i
  # spans @name_offsets[i]...@name_offsets[i + 1] of the sorted, concatenated
  # @names, and its records span @record_offsets[i]...@record_offsets[i + 1] of
  # @records.
  class NameIndex
    def initialize(fname, case_sensitive:)
      @case_sensitive = case_sensitive
      records_by_name = {}
      File.open(fname, 'r:iso8859-1:utf-8') do |f|
        f.each_line do |line|
          eat_name_line records_by_name, line
        end
      end
      build records_by_name
    end

    def include?(name)
      !index(name).nil?
    end

    # The records of the name, or nil for an unknown name.
    def [](name)
      index = index(name)
      slice(@records, @record_offsets, index) if index
    end

    private

    def eat_name_line(records_by_name, line)
      return if line.start_with?('#', '=')

      parts = line.split
      country_values = line.slice(30, COUNTRIES.size).b
      name = @case_sensitive ? parts[1] : parts[1].downcase
      set_name_gender(records_by_name, name, parts[0], country_values)
    end

    def set_name_gender(records_by_name, name, gender, country_values)
      case gender
      when 'M' then set(records_by_name, name, :male, country_values)
      when '1M', '?M' then set(records_by_name, name, :mostly_male, country_values)
      when 'F' then set(records_by_name, name, :female, country_values)
      when '1F', '?F' then set(records_by_name, name, :mostly_female, country_values)
      when '?' then set(records_by_name, name, :andy, country_values)
      else raise "Not sure what to do with a gender of #{gender}"
      end
    end

    def set(records_by_name, name, gender, country_values)
      if name.include? '+'
        ['', '-', ' '].each do |replacement|
          set records_by_name, name.gsub('+', replacement), gender, country_values
        end
      else
        records = records_by_name[name] ||= String.new(encoding: Encoding::BINARY)
        add_record(records, GENDERS.index(gender).chr + country_values)
      end
    end

    # Appends the record, or replaces an earlier record of the same gender in place.
    def add_record(records, record)
      offset = 0.step(records.bytesize - 1, RECORD_SIZE).find { |o| records.getbyte(o) == record.getbyte(0) }
      if offset
        records[offset, RECORD_SIZE] = record
      else
        records << record
      end
    end

    def build(records_by_name)
      names = records_by_name.keys.sort
      @names = names.join.freeze
      @name_offsets = offsets(names.map(&:bytesize))
      @records = names.map { |name| records_by_name[name] }.join.freeze
      @record_offsets = offsets(names.map { |name| records_by_name[name].bytesize })
    end

    def offsets(sizes)
      sizes.each_with_object([0]) { |size, result| result << (result.last + size) }.freeze
    end

    def index(name)
      (0...(@name_offsets.size - 1)).bsearch { |index| name <=> slice(@names, @name_offsets, index) }
    end

    def slice(string, offsets, index)
      string.byteslice(offsets[index], offsets[index + 1] - offsets[index])
    end
  end
end
