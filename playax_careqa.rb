require 'pdf-reader'
require 'strscan'

class Importers
end

class Importers::PdfEcad
    CATEGORIES = {"CA" => "Author", "E" => "Publisher", "V" => "Versionist", "SE" => "SubPublisher"}

    def works
        res = []
        curr = {}
        reader = PDF::Reader.new("careqa.pdf")
        reader.pages.each do |page|
            lines = page.text.split(/\n/)
            lines.each do |line|
                if is_work(line)
                    unless curr.empty?
                        res << curr
                        curr = {}
                    end
                    curr = work(line)
                    curr[:right_holders] = []
                elsif is_right_holder(line)
                    raise 'right holder sem work' if curr == {}
                    rh = right_holder(line)
                    rh.delete(:society_name)
                    rh.delete(:external_ids)
                    curr[:right_holders] << rh
                end
            end
        end
        if curr != {}
            res << curr
            curr = {}
        end
        res
    end


    def right_holder(line)
        return nil unless is_right_holder(line)
        parts = right_holder_to_array(line)
        {
            :name          =>      parts[1],
            :pseudos       =>      [{:name => parts[2],
                                     :main => true }],
            :ipi           =>      parts[3],
            :share         =>      parts[6],
            :role          =>      CATEGORIES.key?(parts[5]) ? CATEGORIES[parts[5]] : '',
            :society_name  =>      parts[4],
            :external_ids  =>      [{:source_name     =>  "Ecad",
                                     :source_id       =>  parts[0]}]
        }
    end


    def work(line)
        return nil unless is_work(line)
        parts = work_to_array(line)
        {
            :iswc          =>      parts[1],
            :title         =>      parts[2],
            :external_ids  =>      [{:source_name => "Ecad", 
                                     :source_id   => parts[0]}],
            :situation     =>      parts[3],
            :created_at    =>      parts[4]
        }
    end


    private


    def right_holder_to_array(line)
        res = []
        scanner = StringScanner.new(line)
        res << scanner.scan(/\d+/)
        scanner.skip(/\s+/)
        res << scanner.scan_until(/\s{2}/).strip
        while res.length < 7
            scanner.skip(/\s+/)
            if scanner.peek(4) =~ /\d{3}\./
                res << nil if res.length == 2
                res << scanner.scan_until(/\s/).gsub('.', '').strip
            elsif CATEGORIES.key?(scanner.check_until(/\s/).strip)
                res << nil while res.length < 5
                res << scanner.scan_until(/\s+/).strip
                res << scanner.scan_until(/\s/).sub(',', '.').to_f.round(2)
            else
                res << nil if res.length == 3
                res << scanner.scan_until(/\s{2}/).strip
            end
        end
        res
    end


    def work_to_array(line)
        res = line.split(/ {2,}|(-\s{3}\.\s{3}\.\s{3}-)/)
        res.delete('')
        res
    end

    def is_right_holder(line)
        (line =~ / +\d+ *$/) && (line =~ /^\d+ {2,}/)
    end


    def is_work(line)
        line =~ /\/\d{4} *$/
    end

end

