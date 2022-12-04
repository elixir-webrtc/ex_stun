defprotocol ExStun.Message.Attribute do
  alias ExStun.Message
  alias ExStun.Message.RawAttribute

  @spec to_raw_attribute(t(), Message.t()) :: RawAttribute.t()
  def to_raw_attribute(attribute, message)
end
