def build_record(attributes = {})
  ActiveRecordMock.new(attributes)
end

def create_record(attributes = {})
  build_record(attributes).tap do |record|
    record.save!
  end
end
