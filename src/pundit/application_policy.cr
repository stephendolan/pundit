abstract class ApplicationPolicy(T)
  getter user
  getter record

  def initialize(@user : User, @record : T? = nil)
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def delete?
    false
  end
end
