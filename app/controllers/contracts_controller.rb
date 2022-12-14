class ContractsController < ApplicationController
  before_action :set_contract, only: [:show, :edit, :update, :destroy]

  def index
    if params[:category].present?
      @contracts = policy_scope(Contract).joins(
        "INNER JOIN products ON products.id = contracts.product_id
        JOIN categories ON categories.id = products.category_id
        AND categories.name = '#{params[:category]}'"
      )
    else
      @contracts = policy_scope(Contract)
    end

    @contracts = @contracts.search_by_company_and_product(params[:query]) if params[:query].present?
    @contracts.order!(active: :desc)
  end

  def show
    @coverqge = Coverage.find_by(contract: @contract)
    authorize @contract
  end

  def new
    @contract = Contract.new
    @company_products = Hash.new
    Company.all.each do |company|

      comp_products = Hash.new
      company.products.each do |product|
        comp_products["#{product.id}"] = product.name
      end

      @company_products["#{company.id}"] = comp_products
    end

    authorize @contract
  end

  def create
    @contract = Contract.new(contract_params)
    @contract.user = current_user

    authorize @contract

    if @contract.save
      redirect_to contracts_path(category: @contract.product.category.name)
    else
      render :new
    end
  end

  def edit
    authorize @contract
  end

  def update
   @contract = Contract.find_by(id: params[:id])
    if @contract.update(contract_params)
      redirect_to contract_path(@contract.id), notice: "Contract was updated"
    else
      render :edit
    end
   authorize @contract
  end

  def destroy
    @contract.destroy
    redirect_to contracts_path(category: @contract.product.category.name), status: :see_other

    authorize @contract
  end

  private

  def contract_params
    params.require(:contract).permit(
      :price, :source, :starts_at, :ends_at, :status, :created_at,
      :updated_at, :pdf_contract, :pdf_certificate,
      :company_id, :product_id, :active, :timing
    )
  end

  def set_contract
    @contract = Contract.find(params[:id])
  end
end
