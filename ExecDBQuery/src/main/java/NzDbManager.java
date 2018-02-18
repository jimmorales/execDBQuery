import java.io.PrintWriter;
import java.sql.*;


public class NzDbManager {

    private Connection conn = null;
    private Statement st = null;
    private ResultSet rs = null;


    public NzDbManager(String server, String port, String database, String uname, String password){
        String URL = "jdbc:netezza://" + server + ":" + port + "/" +database;
        init(URL, uname, password);
    }

    private void init(String URL, String userName, String password){
        try{
            //Class.forName();
            Class.forName("org.netezza.Driver");
            conn = DriverManager.getConnection(URL, userName, password);
        }catch(ClassNotFoundException e){
            System.out.println("Netezza Driver can not be found");
            System.out.println(e.getMessage() + "\n" + e.getStackTrace());
            System.exit(-1);
        }catch (SQLException e){
            System.out.println("Exception in getting a connection");
            System.out.println(e.getMessage() + "\n" + e.getStackTrace());
            System.exit(-1);
        }
    }

    public void printQueryResult(String SQL, String delim){
        try {
            st = conn.createStatement();
            rs = st.executeQuery(SQL);

            ResultSetMetaData rsmd = rs.getMetaData();
            int columnsNumber = rsmd.getColumnCount();

            while (rs.next()) {
                for (int i = 1; i <= columnsNumber; i++) {
                    if (i > 1) System.out.print(delim);
                    System.out.print(rs.getString(i));
                }
                System.out.println("");
            }
        }catch (SQLException e){
            System.out.println("Exception occured while executing the query");
            System.out.println(e.getMessage() + "\n" + e.getStackTrace());
            System.exit(-1);
        }
    }

    public void printQueryResult(String SQL, String delim, String outFile){
        try {
            PrintWriter writer = new PrintWriter(outFile, "UTF-8");
            st = conn.createStatement();
            rs = st.executeQuery(SQL);

            ResultSetMetaData rsmd = rs.getMetaData();
            int columnsNumber = rsmd.getColumnCount();

            while (rs.next()) {
                for (int i = 1; i <= columnsNumber; i++) {
                    if (i > 1) writer.print(delim);
                    writer.print(rs.getString(i));
                }
                writer.println("");
            }
            writer.close();
        }catch (SQLException e){
            System.out.println("Exception occured while executing the query");
            System.out.println(e.getMessage() + "\n" + e.getStackTrace());
            System.exit(-1);
        }catch(Exception e){
            System.err.println("Could not write to output file. Exiting");
            System.out.println(e.getMessage() + "\n" + e.getStackTrace());
            System.exit(-1);
        }
    }

    public void closeAll(){
        try {
            if( rs != null)
                rs.close();
            if( st!= null)
                st.close();
            if( conn != null)
                conn.close();
        } catch (SQLException e1) {
            e1.printStackTrace();
        }
    }

}
