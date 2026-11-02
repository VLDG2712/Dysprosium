/// Phone-side core for Dysprosium: pairing (QR → key + CSR → pinned Pair RPC) and the mTLS client.
library;

export 'src/client.dart' show DysClient, verifyPaired;
export 'src/errors.dart' show DysErrorKind, DysException;
export 'src/ha_wake.dart' show HaWake, HaWakeConfig;
export 'src/gen/dys/v1/dys.pb.dart'
    show
        AdminAccess,
        AlertStatus,
        ApplyProfileReply,
        ApplyProfileReply_Part,
        ControlServiceRequest_Action,
        Cooling,
        CpuStats,
        DiskStats,
        GpuDetail,
        GpuInfo,
        GpuProcess,
        GpuStats,
        InfoItem,
        InfoSection,
        MemStats,
        MinecraftActionRequest_Action,
        MinecraftStatus,
        MountStats,
        NetStats,
        ProcStats,
        ProcessInfo,
        ProcessList,
        Profile,
        ProfileList,
        SensorStats,
        SentAlert,
        ServiceDetail,
        ServiceInfo,
        ServiceList,
        Setting,
        Setting_Kind,
        SettingGroup,
        SignalProcessRequest_Signal,
        Stats,
        SystemInfo,
        SystemSettings,
        PackageUpdate,
        PackageUpdate_Source,
        PingReply,
        PowerRequest_Action,
        RgbDevice,
        RgbDeviceList,
        RgbMode,
        UpdateList,
        UpdateStatus,
        UpdateStatus_State;
export 'src/keys.dart' show DeviceKey;
export 'src/pair_uri.dart' show PairUri, PairUriException;
export 'src/paired_server.dart' show PairedServer;
export 'src/pairing.dart' show isValidDeviceName, pair;
