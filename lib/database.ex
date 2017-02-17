use Amnesia


defdatabase Database do
  # this is just a forward declaration of the table, otherwise you'd have
  # to fully scope User.read in History functions


  deftable History, [:content, :timestamp, :file, :uuid], type: :bag, index: [:timestamp] do
    @type t :: %History{content: String.t, timestamp: Integer.t, file: String.t, uuid: String.t}
  end


  deftable Queue, [:local_file, :remote_file, :uuid], type: :bag do
    @type t :: %Queue{local_file: String.t, remote_file: String.t, uuid: String.t}
  end


end
