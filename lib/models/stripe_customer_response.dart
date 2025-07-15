// models.dart (or stripe_customer_response.dart)

import 'dart:convert';

class StripeCustomerResponse {
  String? id;
  String? object;
  Address? address;
  int? balance;
  int? created;
  String? currency;
  String? defaultSource;
  bool? delinquent;
  String? description;
  dynamic discount; // Could be a Discount object or null
  String? email;
  String? invoicePrefix;
  InvoiceSettings? invoiceSettings;
  bool? livemode;
  Map<String, dynamic>? metadata;
  String? name;
  int? nextInvoiceSequence;
  String? phone;
  List<String>? preferredLocales;
  Shipping? shipping;
  String? taxExempt;
  dynamic testClock; // Could be a TestClock object or null

  StripeCustomerResponse({
    this.id,
    this.object,
    this.address,
    this.balance,
    this.created,
    this.currency,
    this.defaultSource,
    this.delinquent,
    this.description,
    this.discount,
    this.email,
    this.invoicePrefix,
    this.invoiceSettings,
    this.livemode,
    this.metadata,
    this.name,
    this.nextInvoiceSequence,
    this.phone,
    this.preferredLocales,
    this.shipping,
    this.taxExempt,
    this.testClock,
  });

  StripeCustomerResponse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    object = json['object'];
    address = json['address'] != null ? Address.fromJson(json['address']) : null;
    balance = json['balance'];
    created = json['created'];
    currency = json['currency'];
    defaultSource = json['default_source'];
    delinquent = json['delinquent'];
    description = json['description'];
    discount = json['discount']; // Handle discount appropriately
    email = json['email'];
    invoicePrefix = json['invoice_prefix'];
    invoiceSettings = json['invoice_settings'] != null
        ? InvoiceSettings.fromJson(json['invoice_settings'])
        : null;
    livemode = json['livemode'];
    metadata = json['metadata'] == null ? null : (json['metadata'] is String
        ? (jsonDecode(json['metadata']) as Map<String, dynamic>)
        : (json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : null));
    name = json['name'];
    nextInvoiceSequence = json['next_invoice_sequence'];
    phone = json['phone'];
    preferredLocales = json['preferred_locales'] != null
        ? List<String>.from(json['preferred_locales'])
        : null;
    shipping = json['shipping'] != null ? Shipping.fromJson(json['shipping']) : null;
    taxExempt = json['tax_exempt'];
    testClock = json['test_clock']; // Handle test_clock appropriately
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['object'] = object;
    if (address != null) {
      data['address'] = address!.toJson();
    }
    data['balance'] = balance;
    data['created'] = created;
    data['currency'] = currency;
    data['default_source'] = defaultSource;
    data['delinquent'] = delinquent;
    data['description'] = description;
    data['discount'] = discount;
    data['email'] = email;
    data['invoice_prefix'] = invoicePrefix;
    if (invoiceSettings != null) {
      data['invoice_settings'] = invoiceSettings!.toJson();
    }
    data['livemode'] = livemode;
    data['metadata'] = metadata;
    data['name'] = name;
    data['next_invoice_sequence'] = nextInvoiceSequence;
    data['phone'] = phone;
    data['preferred_locales'] = preferredLocales;
    if (shipping != null) {
      data['shipping'] = shipping!.toJson();
    }
    data['tax_exempt'] = taxExempt;
    data['test_clock'] = testClock;
    return data;
  }
}

class Address {
  // Add properties of the Address object if present in the JSON
  Address.fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    return data;
  }
}

class InvoiceSettings {
  // Add properties of the InvoiceSettings object
  InvoiceSettings.fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    return data;
  }
}

class Shipping {
  // Add properties of the Shipping object
  Shipping.fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    return data;
  }
}

// models.dart (or ephemeral_response.dart)

class EphemeralResponse {
  String? id;
  String? object;
  List<AssociatedObject>? associatedObjects;
  int? created;
  int? expires;
  bool? livemode;
  String? secret;

  EphemeralResponse({
    this.id,
    this.object,
    this.associatedObjects,
    this.created,
    this.expires,
    this.livemode,
    this.secret,
  });

  EphemeralResponse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    object = json['object'];
    if (json['associated_objects'] != null) {
      associatedObjects = <AssociatedObject>[];
      json['associated_objects'].forEach((v) {
        associatedObjects!.add(AssociatedObject.fromJson(v));
      });
    }
    created = json['created'];
    expires = json['expires'];
    livemode = json['livemode'];
    secret = json['secret'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['object'] = object;
    if (associatedObjects != null) {
      data['associated_objects'] =
          associatedObjects!.map((v) => v.toJson()).toList();
    }
    data['created'] = created;
    data['expires'] = expires;
    data['livemode'] = livemode;
    data['secret'] = secret;
    return data;
  }
}

class AssociatedObject {
  String? id;
  String? type;

  AssociatedObject({this.id, this.type});

  AssociatedObject.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    return data;
  }
}

// models.dart


// Payment Intent Response
class PaymentIntentResponse {
  String? id;
  String? object;
  int? amount;
  int? amountCapturable;
  AmountDetails? amountDetails;
  int? amountReceived;
  String? application;
  String? applicationFeeAmount;
  AutomaticPaymentMethods? automaticPaymentMethods;
  int? canceledAt;
  String? cancellationReason;
  String? captureMethod;
  String? clientSecret;
  String? confirmationMethod;
  int? created;
  String? currency;
  String? customer;
  String? description;
  String? invoice;
  String? lastPaymentError;
  String? latestCharge;
  bool? livemode;
  Map<String, dynamic>? metadata;
  String? nextAction;
  String? onBehalfOf;
  String? paymentMethod;
  PaymentMethodConfigurationDetails? paymentMethodConfigurationDetails;
  PaymentMethodOptions? paymentMethodOptions;
  List<String>? paymentMethodTypes;
  String? processing;
  String? receiptEmail;
  String? review;
  String? setupFutureUsage;
  Shipping? shipping;
  String? source;
  String? statementDescriptor;
  String? statementDescriptorSuffix;
  String? status;
  String? transferData;
  String? transferGroup;

  PaymentIntentResponse(
      {this.id,
        this.object,
        this.amount,
        this.amountCapturable,
        this.amountDetails,
        this.amountReceived,
        this.application,
        this.applicationFeeAmount,
        this.automaticPaymentMethods,
        this.canceledAt,
        this.cancellationReason,
        this.captureMethod,
        this.clientSecret,
        this.confirmationMethod,
        this.created,
        this.currency,
        this.customer,
        this.description,
        this.invoice,
        this.lastPaymentError,
        this.latestCharge,
        this.livemode,
        this.metadata,
        this.nextAction,
        this.onBehalfOf,
        this.paymentMethod,
        this.paymentMethodConfigurationDetails,
        this.paymentMethodOptions,
        this.paymentMethodTypes,
        this.processing,
        this.receiptEmail,
        this.review,
        this.setupFutureUsage,
        this.shipping,
        this.source,
        this.statementDescriptor,
        this.statementDescriptorSuffix,
        this.status,
        this.transferData,
        this.transferGroup});

  PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    object = json['object'];
    amount = json['amount'];
    amountCapturable = json['amount_capturable'];
    amountDetails = json['amount_details'] != null
        ? AmountDetails.fromJson(json['amount_details'])
        : null;
    amountReceived = json['amount_received'];
    application = json['application'];
    applicationFeeAmount = json['application_fee_amount'];
    automaticPaymentMethods = json['automatic_payment_methods'] != null
        ? AutomaticPaymentMethods.fromJson(json['automatic_payment_methods'])
        : null;
    canceledAt = json['canceled_at'];
    cancellationReason = json['cancellation_reason'];
    captureMethod = json['capture_method'];
    clientSecret = json['client_secret'];
    confirmationMethod = json['confirmation_method'];
    created = json['created'];
    currency = json['currency'];
    customer = json['customer'];
    description = json['description'];
    invoice = json['invoice'];
    lastPaymentError = json['last_payment_error'];
    latestCharge = json['latest_charge'];
    livemode = json['livemode'];
    metadata = json['metadata'] == null ? null : (json['metadata'] is String
        ? (jsonDecode(json['metadata']) as Map<String, dynamic>)
        : (json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : null));
    nextAction = json['next_action'];
    onBehalfOf = json['on_behalf_of'];
    paymentMethod = json['payment_method'];
    paymentMethodConfigurationDetails =
    json['payment_method_configuration_details'] != null
        ? PaymentMethodConfigurationDetails.fromJson(
        json['payment_method_configuration_details'])
        : null;
    paymentMethodOptions = json['payment_method_options'] != null
        ? PaymentMethodOptions.fromJson(json['payment_method_options'])
        : null;
    paymentMethodTypes = json['payment_method_types'] != null
        ? List<String>.from(json['payment_method_types'])
        : null;
    processing = json['processing'];
    receiptEmail = json['receipt_email'];
    review = json['review'];
    setupFutureUsage = json['setup_future_usage'];
    shipping =
    json['shipping'] != null ? Shipping.fromJson(json['shipping']) : null;
    source = json['source'];
    statementDescriptor = json['statement_descriptor'];
    statementDescriptorSuffix = json['statement_descriptor_suffix'];
    status = json['status'];
    transferData = json['transfer_data'];
    transferGroup = json['transfer_group'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['object'] = object;
    data['amount'] = amount;
    data['amount_capturable'] = amountCapturable;
    if (amountDetails != null) {
      data['amount_details'] = amountDetails!.toJson();
    }
    data['amount_received'] = amountReceived;
    data['application'] = application;
    data['application_fee_amount'] = applicationFeeAmount;
    if (automaticPaymentMethods != null) {
      data['automatic_payment_methods'] = automaticPaymentMethods!.toJson();
    }
    data['canceled_at'] = canceledAt;
    data['cancellation_reason'] = cancellationReason;
    data['capture_method'] = captureMethod;
    data['client_secret'] = clientSecret;
    data['confirmation_method'] = confirmationMethod;
    data['created'] = created;
    data['currency'] = currency;
    data['customer'] = customer;
    data['description'] = description;
    data['invoice'] = invoice;
    data['last_payment_error'] = lastPaymentError;
    data['latest_charge'] = latestCharge;
    data['livemode'] = livemode;
    data['metadata'] = metadata;
    data['next_action'] = nextAction;
    data['on_behalf_of'] = onBehalfOf;
    data['payment_method'] = paymentMethod;
    if (paymentMethodConfigurationDetails != null) {
      data['payment_method_configuration_details'] =
          paymentMethodConfigurationDetails!.toJson();
    }
    if (paymentMethodOptions != null) {
      data['payment_method_options'] = paymentMethodOptions!.toJson();
    }
    data['payment_method_types'] = paymentMethodTypes;
    data['processing'] = processing;
    data['receipt_email'] = receiptEmail;
    data['review'] = review;
    data['setup_future_usage'] = setupFutureUsage;
    if (shipping != null) {
      data['shipping'] = shipping!.toJson();
    }
    data['source'] = source;
    data['statement_descriptor'] = statementDescriptor;
    data['statement_descriptor_suffix'] = statementDescriptorSuffix;
    data['status'] = status;
    data['transfer_data'] = transferData;
    data['transfer_group'] = transferGroup;
    return data;
  }
}

class AmountDetails {
  Tip? tip;

  AmountDetails({this.tip});

  AmountDetails.fromJson(Map<String, dynamic> json) {
    tip = json['tip'] != null ? Tip.fromJson(json['tip']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (tip != null) {
      data['tip'] = tip!.toJson();
    }
    return data;
  }
}

class Tip {
  Tip.fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    return data;
  }
}

class PaymentMethodConfigurationDetails {
  String? id;
  String? parent;

  PaymentMethodConfigurationDetails({this.id, this.parent});

  PaymentMethodConfigurationDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    parent = json['parent'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['parent'] = parent;
    return data;
  }
}

class PaymentMethodOptions {
  Card? card;
  Link? link;

  PaymentMethodOptions({this.card, this.link});

  PaymentMethodOptions.fromJson(Map<String, dynamic> json) {
    card = json['card'] != null ? Card.fromJson(json['card']) : null;
    link = json['link'] != null ? Link.fromJson(json['link']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (card != null) {
      data['card'] = card!.toJson();
    }
    if (link != null) {
      data['link'] = link!.toJson();
    }
    return data;
  }
}

class Card {
  String? installments;
  String? mandateOptions;
  String? network;
  String? requestThreeDSecure;

  Card({this.installments, this.mandateOptions, this.network, this.requestThreeDSecure});

  Card.fromJson(Map<String, dynamic> json) {
    installments = json['installments']?.toString();
    mandateOptions = json['mandate_options']?.toString();
    network = json['network'];
    requestThreeDSecure = json['request_three_d_secure'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['installments'] = installments;
    data['mandate_options'] = mandateOptions;
    data['network'] = network;
    data['request_three_d_secure'] = requestThreeDSecure;
    return data;
  }
}

class Link {
  String? persistentToken;

  Link({this.persistentToken});

  Link.fromJson(Map<String, dynamic> json) {
    persistentToken = json['persistent_token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['persistent_token'] = persistentToken;
    return data;
  }
}



class AutomaticPaymentMethods {
  final bool enabled;

  AutomaticPaymentMethods({required this.enabled});

  factory AutomaticPaymentMethods.fromJson(Map<String, dynamic> json) {
    final dynamic enabledValue = json['enabled'];
    bool enabledBool;
    if (enabledValue is String) {
      enabledBool = enabledValue.toLowerCase() == 'true';
    } else if (enabledValue is bool) {
      enabledBool = enabledValue;
    } else {
      enabledBool = false;
    }

    return AutomaticPaymentMethods(
      enabled: enabledBool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
    };
  }
}