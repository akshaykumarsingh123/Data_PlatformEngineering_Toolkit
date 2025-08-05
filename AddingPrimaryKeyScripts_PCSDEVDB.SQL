ALTER TABLE PCS_Supp.Dim_Adjustments
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Dim_Adjustments
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Dim_Base_Contracts
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Dim_Base_Contracts
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Dim_Booking_Interface_Type
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Dim_Booking_Interface_Type
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Dim_DayMap
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Dim_DayMap
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Dim_EBB
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Dim_EBB
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.DIM_SEASON_HELPER
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.DIM_SEASON_HELPER
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Stg_Connected_Hotel_Rates
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Stg_Connected_Hotel_Rates
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_booking_to_contract
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_booking_to_contract
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_booking_to_contract_adj
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_booking_to_contract_adj
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_booking_to_contract_adj_daily
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_booking_to_contract_adj_daily
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_booking_to_contract_daily
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_booking_to_contract_daily
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_booking_to_contract_promo
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_booking_to_contract_promo
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_booking_to_contract_promo_daily
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_booking_to_contract_promo_daily
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_booking_to_cost_formula
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_booking_to_cost_formula
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_Bookings
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_Bookings
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_Child_Adjustments
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_Child_Adjustments
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_Child_Base_Contracts
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_Child_Base_Contracts
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_Cons_Bookings
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_Cons_Bookings
ADD PRIMARY KEY (PCS_ID)
GO
===========================================================================================

ALTER TABLE PCS_Supp.Temp_Copied_Contracts_ToDelete
ADD PCS_ID BIGINT IDENTITY
GO
ALTER TABLE PCS_Supp.Temp_Copied_Contracts_ToDelete
ADD PRIMARY KEY (PCS_ID)
GO
===================================================================================

