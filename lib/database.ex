use Amnesia


defdatabase Database do
  # this is just a forward declaration of the table, otherwise you'd have
  # to fully scope User.read in History functions
  deftable User


  deftable History, [:user_id, :content, :timestamp, :file], type: :bag do
    @type t :: %History{user_id: integer, content: String.t, timestamp: String.t, file: String.t}

    # this defines a helper function to fetch the user from a History record
    def user self do
      User.read self.user_id
    end

  end


  deftable Queue, [:user_id, :local_file, :remote_file, :uuid], type: :bag do
    @type t :: %Queue{user_id: integer, local_file: String.t, remote_file: String.t, uuid: String.t}

    def user self do
      User.read self.user_id
    end
  end


  deftable User, [{ :id, autoincrement }, :name], type: :set, index: [:name] do
    @type t :: %User{id: non_neg_integer, name: String.t}


    def add_history self, content, file do
      %History{user_id: self.id, content: content, timestamp: Timestamp.now, file: file} |> History.write
    end


    def histories self do
      hist = History.read self.id
      case hist do
        nil ->
          []

        hists ->
          hists
      end
    end


    def add_to_queue _self, record do
      record |> Queue.write
    end


    def remove_from_queue _self, record do
      record |> Queue.delete
    end


    def queue self do
      Queue.read self.id
    end

  end


end
