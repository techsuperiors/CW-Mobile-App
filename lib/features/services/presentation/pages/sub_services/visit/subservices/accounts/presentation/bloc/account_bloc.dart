import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_accounts_usecase.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetAccountCustomersUseCase getAccountCustomersUseCase;
  final GetAccountAddressesUseCase getAccountAddressesUseCase;
  final GetAccountCustomerDetailsUseCase getAccountCustomerDetailsUseCase;
  final GetAccountAddressDetailsUseCase getAccountAddressDetailsUseCase;
  final CreateAccountAddressUseCase createAccountAddressUseCase;
  final CreateAccountCustomerUseCase createAccountCustomerUseCase;

  AccountBloc({
    required this.getAccountCustomersUseCase,
    required this.getAccountAddressesUseCase,
    required this.getAccountCustomerDetailsUseCase,
    required this.getAccountAddressDetailsUseCase,
    required this.createAccountAddressUseCase,
    required this.createAccountCustomerUseCase,
  }) : super(const AccountState()) {
    on<LoadAccountCustomers>(_onLoadAccountCustomers);
    on<LoadAccountAddresses>(_onLoadAccountAddresses);
    on<LoadAccountCustomerDetails>(_onLoadAccountCustomerDetails);
    on<LoadAccountAddressDetails>(_onLoadAccountAddressDetails);
    on<CreateAccountAddressRequested>(_onCreateAccountAddressRequested);
    on<CreateAccountCustomerRequested>(_onCreateAccountCustomerRequested);
    on<ClearAccountFeedback>(_onClearAccountFeedback);
  }

  Future<void> _onLoadAccountCustomers(
    LoadAccountCustomers event,
    Emitter<AccountState> emit,
  ) async {
    if (state.isCustomersLoading) return;
    if (!event.forceRefresh && state.customers.isNotEmpty) return;

    emit(
      state.copyWith(
        isCustomersLoading: true,
        customersError: null,
        customers: event.forceRefresh ? const [] : state.customers,
      ),
    );

    final result = await getAccountCustomersUseCase();
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isCustomersLoading: false,
            customersError: failure.message,
          ),
        );
      },
      (customers) {
        emit(
          state.copyWith(
            isCustomersLoading: false,
            customers: customers,
            customersError: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadAccountAddresses(
    LoadAccountAddresses event,
    Emitter<AccountState> emit,
  ) async {
    if (state.isAddressesLoading) return;
    if (!event.forceRefresh && state.addresses.isNotEmpty) return;

    emit(
      state.copyWith(
        isAddressesLoading: true,
        addressesError: null,
        addresses: event.forceRefresh ? const [] : state.addresses,
      ),
    );

    final result = await getAccountAddressesUseCase();
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isAddressesLoading: false,
            addressesError: failure.message,
          ),
        );
      },
      (addresses) {
        emit(
          state.copyWith(
            isAddressesLoading: false,
            addresses: addresses,
            addressesError: null,
          ),
        );
      },
    );
  }

  Future<void> _onCreateAccountCustomerRequested(
    CreateAccountCustomerRequested event,
    Emitter<AccountState> emit,
  ) async {
    if (state.isCreatingCustomer) return;

    emit(
      state.copyWith(
        isCreatingCustomer: true,
        actionError: null,
        successMessage: null,
      ),
    );

    final result = await createAccountCustomerUseCase(event.params);
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isCreatingCustomer: false,
            actionError: failure.message,
            successMessage: null,
          ),
        );
      },
      (message) {
        emit(
          state.copyWith(
            isCreatingCustomer: false,
            successMessage: message,
            actionError: null,
          ),
        );
      },
    );
  }

  Future<void> _onCreateAccountAddressRequested(
    CreateAccountAddressRequested event,
    Emitter<AccountState> emit,
  ) async {
    if (state.isCreatingAddress) return;

    emit(
      state.copyWith(
        isCreatingAddress: true,
        actionError: null,
        successMessage: null,
      ),
    );

    final result = await createAccountAddressUseCase(event.params);
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isCreatingAddress: false,
            actionError: failure.message,
            successMessage: null,
          ),
        );
      },
      (message) {
        emit(
          state.copyWith(
            isCreatingAddress: false,
            successMessage: message,
            actionError: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadAccountCustomerDetails(
    LoadAccountCustomerDetails event,
    Emitter<AccountState> emit,
  ) async {
    final existingDetail = state.customerDetail;
    if (state.isCustomerDetailLoading) return;
    if (!event.forceRefresh &&
        existingDetail != null &&
        existingDetail.id == event.customerId) {
      return;
    }

    emit(
      state.copyWith(
        isCustomerDetailLoading: true,
        customerDetailError: null,
        customerDetail: null,
      ),
    );

    final result = await getAccountCustomerDetailsUseCase(event.customerId);
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isCustomerDetailLoading: false,
            customerDetailError: failure.message,
          ),
        );
      },
      (detail) {
        emit(
          state.copyWith(
            isCustomerDetailLoading: false,
            customerDetail: detail,
            customerDetailError: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadAccountAddressDetails(
    LoadAccountAddressDetails event,
    Emitter<AccountState> emit,
  ) async {
    final existingDetail = state.addressDetail;
    if (state.isAddressDetailLoading) return;
    if (!event.forceRefresh &&
        existingDetail != null &&
        existingDetail.id == event.addressId) {
      return;
    }

    emit(
      state.copyWith(
        isAddressDetailLoading: true,
        addressDetailError: null,
        addressDetail: null,
      ),
    );

    final result = await getAccountAddressDetailsUseCase(event.addressId);
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isAddressDetailLoading: false,
            addressDetailError: failure.message,
          ),
        );
      },
      (detail) {
        emit(
          state.copyWith(
            isAddressDetailLoading: false,
            addressDetail: detail,
            addressDetailError: null,
          ),
        );
      },
    );
  }

  void _onClearAccountFeedback(
    ClearAccountFeedback event,
    Emitter<AccountState> emit,
  ) {
    emit(state.copyWith(actionError: null, successMessage: null));
  }
}
