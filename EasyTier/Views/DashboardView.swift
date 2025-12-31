import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var showNewNameAlert = false
    @State private var showSheet = false
    @State private var newNameInput = ""

    init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel())
    }

    var body: some View {
        VStack {
            headerView
                .padding([.horizontal, .top])
            if (viewModel.selectedNetworkId == nil) {
                Spacer()
                Image(systemName: "network.slash")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(Color.accentColor)
                Text("Please select a network.")
                Spacer()
            } else {
                ZStack {
                    NetworkEditView()
                        .disabled(viewModel.isPending)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "chevron.up.chevron.down")
                .onTapGesture {
                    showSheet = true
                }
            Text(viewModel.selectedNetwork?.name ?? "Select Network")
                .font(.largeTitle.bold())
                .onTapGesture {
                    showSheet = true
                }
            Spacer()
            Button(viewModel.isConnected ? "Disconnect" : "Connect", systemImage: viewModel.isConnected ? "cable.connector.slash" : "cable.connector") {
                viewModel.isConnected = !viewModel.isConnected
            }
            .disabled(viewModel.isPending || viewModel.selectedNetworkId == nil)
            .buttonStyle(.glass)
            .tint(viewModel.isConnected ? Color.red : Color.accentColor)
            .animation(.interactiveSpring, value: viewModel.isConnected)
        }
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                List {
                    Section("Network") {
                        ForEach(viewModel.networks, id: \.self) { item in
                            Button {
                                viewModel.selectedNetworkId = item.id
                            } label: {
                                HStack {
                                    Text(item.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if viewModel.selectedNetworkId == item.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.networks.remove(atOffsets: indexSet)
                            if viewModel.selectedNetworkId == nil {
                                viewModel.selectedNetworkId = viewModel.networks.first?.id
                            }
                        }
                    }
                    Section("Manage") {
                        Button {
                            showNewNameAlert = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "document.badge.plus")
                                Text("Create a network")
                            }
                        }
                        Button {
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.down.document")
                                Text("Import from file")
                            }
                        }
                        Button {
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "long.text.page.and.pencil")
                                Text("Edit in text")
                            }
                        }
                    }
                }
                .navigationTitle("Manage Networks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button {
                        showSheet = false
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .alert("New Network", isPresented: $showNewNameAlert) {
                    TextField("Name of the new network", text: $newNameInput)
                        .textInputAutocapitalization(.never)
                    Button(role: .cancel) { }
                    Button(role: .confirm) {
                        viewModel.newNetwork(name: newNameInput)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
